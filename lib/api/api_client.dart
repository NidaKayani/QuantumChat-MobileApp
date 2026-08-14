import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../crypto/key_storage.dart';
import '../crypto/qc_crypto.dart';
import '../models/models.dart';

class ApiClient {
  ApiClient({required this.baseUrl, required this.storage});

  String baseUrl;
  final KeyStorage storage;

  Uri _uri(String path, [Map<String, String>? query]) {
    final root = baseUrl.replaceAll(RegExp(r'/$'), '');
    return Uri.parse('$root$path').replace(queryParameters: query);
  }

  Map<String, String> _headers({bool json = true}) {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    final token = storage.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  dynamic _decode(http.Response res) {
    dynamic body;
    try {
      body = jsonDecode(res.body);
    } catch (_) {
      body = null;
    }
    if (res.statusCode >= 400) {
      final error = body is Map ? (body['error'] as String? ?? 'Request failed') : 'Request failed';
      throw ApiException(error, status: res.statusCode);
    }
    if (body is Map && body['success'] == false) {
      throw ApiException(body['error'] as String? ?? 'Request failed', status: res.statusCode);
    }
    return body;
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final res = await http.get(_uri(path, query), headers: _headers()).timeout(const Duration(seconds: 20));
    return _decode(res);
  }

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) async {
    final res = await http
        .post(
          _uri(path),
          headers: _headers(),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    return _decode(res);
  }

  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) async {
    final res = await http.patch(
      _uri(path),
      headers: _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(res);
  }

  Future<dynamic> put(String path, [Map<String, dynamic>? body]) async {
    final res = await http.put(
      _uri(path),
      headers: _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await http.delete(_uri(path), headers: _headers());
    return _decode(res);
  }

  Future<Uint8List?> getBytes(String path) async {
    final res = await http.get(_uri(path), headers: _headers(json: false));
    if (res.statusCode >= 400) return null;
    return res.bodyBytes;
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required List<String> publicKeys,
  }) async {
    final body = _decode(await http.post(
      _uri('/auth/register'),
      headers: _headers(),
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'publicKeys': publicKeys,
      }),
    ));
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String deviceLabel,
    bool rememberMe = true,
  }) async {
    final body = _decode(await http.post(
      _uri('/auth/login'),
      headers: _headers(),
      body: jsonEncode({
        'email': email,
        'password': password,
        'deviceLabel': deviceLabel,
        'rememberMe': rememberMe,
      }),
    ));
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verify2fa({
    required String tempToken,
    required String token,
    required String deviceLabel,
    bool rememberMe = true,
  }) async {
    final body = await post('/auth/2fa/verify', {
      'tempToken': tempToken,
      'token': token,
      'deviceLabel': deviceLabel,
      'rememberMe': rememberMe,
    });
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> me() async {
    final body = await get('/auth/me');
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final body = await post('/auth/forgot-password', {'email': email});
    return (body['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<void> resetPassword({required String token, required String newPassword}) async {
    await post('/auth/reset-password', {'token': token, 'newPassword': newPassword});
  }

  Future<void> resendVerification() async {
    await post('/auth/resend-verification');
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    await post('/auth/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<List<QcUser>> listUsers({String q = '', String? cursor}) async {
    final query = <String, String>{'limit': '40'};
    if (q.isNotEmpty) query['q'] = q;
    if (cursor != null) query['cursor'] = cursor;
    final body = await get('/users', query: query);
    final data = body['data'] as List<dynamic>? ?? [];
    return data.map((e) => QcUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<QcUser> getUser(String id) async {
    final body = await get('/users/$id');
    return QcUser.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getMyPublicKeys() async {
    final body = await get('/users/me/public-keys');
    return (body['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<QcUser> updatePublicKeys(List<String> publicKeys) async {
    final body = await patch('/users/me/public-keys', {'publicKeys': publicKeys});
    return QcUser.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<QcUser> updateProfile(Map<String, dynamic> payload) async {
    final body = await patch('/users/me', payload);
    return QcUser.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<QcUser> updatePrivacy(Map<String, dynamic> payload) async {
    final body = await patch('/users/me/privacy', payload);
    return QcUser.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<List<QcUser>> listFriends() async {
    final body = await get('/users/friends');
    final data = body['data'] as List<dynamic>? ?? [];
    return data.map((e) => QcUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Map<String, dynamic>>> friendRequests() async {
    final body = await get('/users/friend-requests');
    final data = body['data'];
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    if (data is Map) {
      return [
        ...(data['incoming'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      ];
    }
    return [];
  }

  Future<void> sendFriendRequest(String userId) async {
    await post('/users/friend-requests', {'to': userId});
  }

  Future<void> acceptFriendRequest(String id) async {
    await post('/users/friend-requests/$id/accept');
  }

  Future<void> declineFriendRequest(String id) async {
    await post('/users/friend-requests/$id/decline');
  }

  Future<Map<String, dynamic>?> lookupContact(String q) async {
    final body = await get('/users/lookup', query: {'q': q});
    return body['data'] as Map<String, dynamic>?;
  }

  Future<List<QcUser>> listBlocked() async {
    final body = await get('/users/me/blocked');
    final data = body['data'] as List<dynamic>? ?? [];
    return data.map((e) => QcUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> blockUser(String id) async => post('/users/$id/block');
  Future<void> unblockUser(String id) async => delete('/users/$id/block');

  Future<List<QcGroup>> listGroups({String q = ''}) async {
    final query = <String, String>{'limit': '50'};
    if (q.isNotEmpty) query['q'] = q;
    final body = await get('/groups', query: query);
    final data = body['data'] as List<dynamic>? ?? [];
    return data.map((e) => QcGroup.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<QcGroup> createGroup({
    required String name,
    String description = '',
    List<String> memberIds = const [],
  }) async {
    final body = await post('/groups', {
      'name': name,
      'description': description,
      'memberIds': memberIds,
    });
    return QcGroup.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> getConversation(String userId, {String? before}) async {
    final query = <String, String>{'limit': '50'};
    if (before != null) query['before'] = before;
    final body = await get('/messages/$userId', query: query);
    return (body['data'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> sendMessage(Map<String, dynamic> payload) async {
    final body = await post('/messages', payload);
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> editMessage(String id, Map<String, dynamic> payload) async {
    final body = await patch('/messages/$id', payload);
    return body['data'] as Map<String, dynamic>;
  }

  Future<void> deleteMessage(String id, {bool forEveryone = false}) async {
    await http.delete(
      _uri('/messages/$id').replace(queryParameters: {
        if (forEveryone) 'forEveryone': 'true',
      }),
      headers: _headers(),
    );
  }

  Future<void> markRead(String userId) async {
    await post('/messages/$userId/read');
  }

  Future<Map<String, dynamic>> reactToMessage(String id, Map<String, dynamic> payload) async {
    final body = await post('/messages/$id/reactions', payload);
    return body['data'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getGroupMessages(String groupId, {String? before}) async {
    final query = <String, String>{'limit': '50'};
    if (before != null) query['before'] = before;
    final body = await get('/groups/$groupId/messages', query: query);
    return (body['data'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> sendGroupMessage(String groupId, Map<String, dynamic> payload) async {
    final body = await post('/groups/$groupId/messages', payload);
    return body['data'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> syncMessages({String? since}) async {
    final query = <String, String>{};
    if (since != null) query['since'] = since;
    final body = await get('/messages/sync', query: query);
    return (body['data'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> uploadSealedAttachment({
    required Uint8List cipherBytes,
    required String filename,
    required String recipientId,
    required SealedEnvelope envelope,
    required String mimetype,
  }) async {
    final request = http.MultipartRequest('POST', _uri('/attachments'));
    request.headers.addAll(_headers(json: false));
    request.fields['recipientId'] = recipientId;
    request.fields['nonce'] = envelope.nonce;
    request.fields['ephemeralPublicKey'] = envelope.ephemeralPublicKey;
    request.fields['targetPublicKey'] = envelope.targetPublicKey;
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      cipherBytes,
      filename: filename,
    ));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    final body = _decode(res);
    return body['data'] as Map<String, dynamic>;
  }

  String avatarUrl(String userId) => '${baseUrl.replaceAll(RegExp(r'/$'), '')}/users/$userId/avatar';
}
