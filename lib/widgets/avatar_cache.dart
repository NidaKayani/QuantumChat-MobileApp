import 'dart:typed_data';

import '../api/api_client.dart';

/// In-memory cache for user avatars and group photos (auth-required downloads).
class AvatarCache {
  AvatarCache._();
  static final instance = AvatarCache._();

  final Map<String, Uint8List> _cache = {};
  final Map<String, Future<Uint8List?>> _inFlight = {};

  String _key(String id, {bool isGroup = false}) => '${isGroup ? 'g' : 'u'}:$id';

  Future<Uint8List?> load(ApiClient api, String id, {bool isGroup = false}) async {
    final key = _key(id, isGroup: isGroup);
    final cached = _cache[key];
    if (cached != null) return cached;
    final pending = _inFlight[key];
    if (pending != null) return pending;

    final future = _fetch(api, id, isGroup: isGroup);
    _inFlight[key] = future;
    try {
      final bytes = await future;
      if (bytes != null && bytes.isNotEmpty) {
        _cache[key] = bytes;
      }
      return bytes;
    } finally {
      _inFlight.remove(key);
    }
  }

  Future<Uint8List?> _fetch(ApiClient api, String id, {bool isGroup = false}) async {
    final path = isGroup ? '/groups/$id/photo' : '/users/$id/avatar';
    return api.getBytes(path);
  }

  void bust(String id, {bool isGroup = false}) {
    final key = _key(id, isGroup: isGroup);
    _cache.remove(key);
    _inFlight.remove(key);
  }
}
