import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../api/qc_socket.dart';
import '../crypto/key_storage.dart';
import '../crypto/qc_crypto.dart';
import '../models/models.dart';
import 'auth_controller.dart';

class ChatController extends ChangeNotifier {
  ChatController({required this.auth, required this.storage, required this.socket});

  final AuthController auth;
  final KeyStorage storage;
  final QcSocket socket;

  List<QcUser> users = [];
  List<QcUser> friends = [];
  List<QcGroup> groups = [];
  List<Conversation> conversations = [];
  List<ChatMessage> messages = [];
  List<FriendRequest> friendRequests = [];
  List<StoryItem> stories = [];
  Conversation? selected;
  ChatMessage? replyTo;
  ChatMessage? editing;
  String filter = 'all';
  String search = '';
  bool loadingInbox = false;
  bool loadingThread = false;
  bool sending = false;
  String? threadError;
  String? typingFrom;
  final Set<String> onlineUserIds = {};
  int incomingRequestCount = 0;
  Timer? _typingDebounce;
  Timer? _pollTimer;
  String? _joinedGroupId;
  bool _started = false;

  QcUser get me => auth.user!;

  Future<void> start() async {
    if (!_started) {
      _bindSocket();
      _started = true;
    }
    await refreshInbox();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (auth.user == null || !auth.hasLocalKeyring) return;
      if (socket.connected) return;
      _pollSync();
    });
  }

  void stop() {
    _started = false;
    _pollTimer?.cancel();
    _typingDebounce?.cancel();
    socket.off('message:new');
    socket.off('message:status');
    socket.off('presence:snapshot');
    socket.off('presence:update');
    socket.off('typing:start');
    socket.off('typing:stop');
    socket.off('friend:request:new');
    socket.off('friend:request:accepted');
  }

  void _bindSocket() {
    socket.on('message:new', (raw) async {
      if (raw is! Map) return;
      final map = Map<String, dynamic>.from(raw);
      await _noteActivity(map);
      final msg = await decorate(map);
      final inView = selected != null && _messageBelongs(msg, selected!);
      if (inView) {
        final exists = messages.any((m) => m.id == msg.id);
        if (!exists) {
          messages = [...messages, msg];
          notifyListeners();
        }
        if (!msg.isMine(me.id)) {
          socket.markDelivered(msg.id);
          unawaited(auth.api.markRead(selected!.type == ConversationType.dm ? selected!.id : msg.from));
        }
      }
      _rebuildConversations();
    });
    socket.on('message:status', (raw) {
      if (raw is! Map) return;
      final id = '${raw['id']}';
      messages = messages.map((m) {
        if (m.id != id) return m;
        m.deliveredAt = _parseDate(raw['deliveredAt']) ?? m.deliveredAt;
        m.readAt = _parseDate(raw['readAt']) ?? m.readAt;
        return m;
      }).toList();
      notifyListeners();
    });
    socket.on('presence:snapshot', (raw) {
      onlineUserIds
        ..clear()
        ..addAll(((raw is Map ? raw['onlineUserIds'] : null) as List<dynamic>? ?? []).map((e) => '$e'));
      _rebuildConversations();
    });
    socket.on('presence:update', (raw) {
      if (raw is! Map) return;
      final id = '${raw['userId']}';
      if (raw['online'] == true) {
        onlineUserIds.add(id);
      } else {
        onlineUserIds.remove(id);
      }
      _rebuildConversations();
    });
    socket.on('typing:start', (raw) {
      if (raw is! Map || selected == null) return;
      final from = '${raw['from']}';
      if (from == me.id) return;
      final groupId = raw['groupId']?.toString();
      if (selected!.type == ConversationType.group) {
        if (groupId == selected!.id) typingFrom = from;
      } else if (from == selected!.id) {
        typingFrom = from;
      }
      notifyListeners();
    });
    socket.on('typing:stop', (raw) {
      if (raw is! Map) return;
      if ('${raw['from']}' == typingFrom) {
        typingFrom = null;
        notifyListeners();
      }
    });
    socket.on('friend:request:new', (_) {
      unawaited(_refreshFriendRequests());
    });
    socket.on('friend:request:accepted', (_) {
      unawaited(refreshInbox());
    });
  }

  Future<void> _refreshFriendRequests() async {
    try {
      friendRequests = await auth.api.friendRequestsIncoming();
      incomingRequestCount = friendRequests.length;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshStories() async {
    try {
      stories = await auth.api.listStories();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> acceptFriendRequest(String id) async {
    await auth.api.acceptFriendRequest(id);
    await refreshInbox();
  }

  Future<void> declineFriendRequest(String id) async {
    await auth.api.declineFriendRequest(id);
    await _refreshFriendRequests();
  }

  Future<void> blockPeer(String userId) async {
    await auth.api.blockUser(userId);
    await refreshInbox();
  }

  Future<void> muteSelected({String duration = 'always'}) async {
    final conv = selected;
    if (conv == null) return;
    if (conv.type == ConversationType.dm) {
      await auth.api.muteChat(peerId: conv.id, duration: duration);
    } else {
      await auth.api.muteChat(groupId: conv.id, duration: duration);
    }
    conv.muted = true;
    notifyListeners();
  }

  Future<void> unmuteSelected() async {
    final conv = selected;
    if (conv == null) return;
    if (conv.type == ConversationType.dm) {
      await auth.api.unmuteChat(peerId: conv.id);
    } else {
      await auth.api.unmuteChat(groupId: conv.id);
    }
    conv.muted = false;
    notifyListeners();
  }

  Future<void> clearSelectedChat() async {
    final conv = selected;
    if (conv == null) return;
    if (conv.type == ConversationType.dm) {
      await auth.api.clearChat(peerId: conv.id);
    } else {
      await auth.api.clearChat(groupId: conv.id);
    }
    messages = [];
    notifyListeners();
  }

  void setReplyTo(ChatMessage? message) {
    replyTo = message;
    editing = null;
    notifyListeners();
  }

  void setEditing(ChatMessage? message) {
    editing = message;
    replyTo = null;
    notifyListeners();
  }

  void clearComposerContext() {
    replyTo = null;
    editing = null;
    notifyListeners();
  }

  Future<void> refreshInbox() async {
    if (!auth.hasLocalKeyring) return;
    loadingInbox = true;
    notifyListeners();
    try {
      users = await auth.api.listUsers();
      groups = await auth.api.listGroups();
      try {
        friends = await auth.api.listFriends();
      } catch (_) {
        friends = [];
      }
      await _refreshFriendRequests();
      await refreshStories();
      _rebuildConversations();
    } on ApiException catch (e) {
      threadError = e.message;
      notifyListeners();
    } finally {
      loadingInbox = false;
      notifyListeners();
    }
  }

  Future<void> searchPeople(String q) async {
    search = q;
    if (q.trim().length < 2) {
      await refreshInbox();
      return;
    }
    users = await auth.api.listUsers(q: q.trim());
    groups = await auth.api.listGroups(q: q.trim());
    _rebuildConversations();
  }

  void setFilter(String next) {
    filter = next;
    _rebuildConversations();
  }

  void _rebuildConversations() {
    final items = <Conversation>[];
    final self = Conversation(
      key: storage.conversationKeyForUser(me.id),
      type: ConversationType.dm,
      id: me.id,
      title: 'Message yourself',
      subtitle: 'Notes to self',
      peer: me,
      isSelfChat: true,
      sortAt: storage.getConversationActivity(me.id, storage.conversationKeyForUser(me.id))?.at ?? '',
    );
    self.unread = storage.isUnread(me.id, self.key, self.sortAt.isEmpty ? null : self.sortAt, null);
    items.add(self);

    for (final u in users) {
      if (u.id == me.id) continue;
      final key = storage.conversationKeyForUser(u.id);
      final activity = storage.getConversationActivity(me.id, key);
      items.add(Conversation(
        key: key,
        type: ConversationType.dm,
        id: u.id,
        title: u.title,
        peer: u,
        unread: storage.isUnread(me.id, key, activity?.at, activity?.from),
        sortAt: activity?.at ?? u.lastLoginAt?.toIso8601String() ?? '',
        online: onlineUserIds.contains(u.id) && u.privacy.online != 'nobody',
      ));
    }
    for (final g in groups) {
      final key = storage.conversationKeyForGroup(g.id);
      final activity = storage.getConversationActivity(me.id, key);
      final count = g.members.length;
      items.add(Conversation(
        key: key,
        type: ConversationType.group,
        id: g.id,
        title: g.name,
        subtitle: g.description.isNotEmpty
            ? g.description
            : '$count member${count == 1 ? '' : 's'}',
        group: g,
        unread: storage.isUnread(me.id, key, activity?.at, activity?.from),
        sortAt: activity?.at ?? g.updatedAt?.toIso8601String() ?? '',
      ));
    }

    items.sort((a, b) {
      if (a.isSelfChat != b.isSelfChat) return a.isSelfChat ? -1 : 1;
      if (a.unread != b.unread) return a.unread ? -1 : 1;
      return b.sortAt.compareTo(a.sortAt);
    });

    final q = search.trim().toLowerCase();
    conversations = items.where((c) {
      if (filter == 'groups' && c.type != ConversationType.group) return false;
      if (filter == 'unread' && !c.unread) return false;
      if (filter == 'friends') {
        if (c.isSelfChat) return true;
        if (c.type != ConversationType.dm) return false;
        return friends.any((f) => f.id == c.id);
      }
      if (q.isNotEmpty && !c.title.toLowerCase().contains(q) && !(c.subtitle ?? '').toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
    notifyListeners();
  }

  Future<void> open(Conversation conv) async {
    if (_joinedGroupId != null && _joinedGroupId != conv.id) {
      socket.leaveGroup(_joinedGroupId!);
      _joinedGroupId = null;
    }
    selected = conv;
    typingFrom = null;
    messages = [];
    loadingThread = true;
    threadError = null;
    notifyListeners();
    if (conv.type == ConversationType.group) {
      socket.joinGroup(conv.id);
      _joinedGroupId = conv.id;
    }
    try {
      final raw = conv.type == ConversationType.dm
          ? await auth.api.getConversation(conv.id)
          : await auth.api.getGroupMessages(conv.id);
      final decorated = <ChatMessage>[];
      for (final row in raw) {
        decorated.add(await decorate(row));
      }
      messages = decorated;
      await storage.markConversationRead(me.id, conv.key);
      conv.unread = false;
      if (conv.type == ConversationType.dm) {
        unawaited(auth.api.markRead(conv.id));
      }
      for (final m in messages.where((m) => !m.isMine(me.id))) {
        socket.markDelivered(m.id);
      }
      _rebuildConversations();
    } on ApiException catch (e) {
      threadError = e.message;
    } finally {
      loadingThread = false;
      notifyListeners();
    }
  }

  void closeThread() {
    if (_joinedGroupId != null) {
      socket.leaveGroup(_joinedGroupId!);
      _joinedGroupId = null;
    }
    selected = null;
    messages = [];
    typingFrom = null;
    notifyListeners();
  }

  Future<ChatMessage> decorate(Map<String, dynamic> raw) async {
    final from = '${raw['from']}';
    final isMine = from == me.id;
    String? text;
    Map<String, dynamic>? groupFileMeta;
    if (raw['group'] != null && raw['content'] is String && (raw['content'] as String).isNotEmpty) {
      text = raw['content'] as String;
    } else if (raw['group'] != null && raw['envelopes'] is List) {
      final envelopes = (raw['envelopes'] as List).whereType<Map>();
      Map<String, dynamic>? mineEnv;
      for (final e in envelopes) {
        if ('${e['user']}' == me.id) mineEnv = Map<String, dynamic>.from(e);
      }
      if (mineEnv != null) {
        try {
          final env = SealedEnvelope.fromJson(mineEnv);
          final sk = await storage.findSecretKeyForPublicKey(me.id, env.targetPublicKey);
          text = sk == null ? null : unsealMessage(env, sk);
        } catch (_) {
          text = null;
        }
      }
    } else {
      final envelopeJson = isMine ? raw['forSender'] : raw['forRecipient'];
      if (envelopeJson is Map) {
        try {
          final env = SealedEnvelope.fromJson(Map<String, dynamic>.from(envelopeJson));
          final sk = await storage.findSecretKeyForPublicKey(me.id, env.targetPublicKey);
          text = sk == null ? null : unsealMessage(env, sk);
        } catch (_) {
          text = null;
        }
      }
    }

    if (text != null && text.trim().startsWith('{')) {
      try {
        final obj = jsonDecode(text) as Map<String, dynamic>;
        if (obj['__qc'] == 1 && obj['type'] == 'announcement') {
          text = obj['body'] as String? ?? text;
        } else if (obj['__qc'] == 1 && obj['type'] == 'text') {
          text = obj['body'] as String? ?? text;
        } else if (obj['__qc'] == 1 && obj['type'] == 'file') {
          text = obj['filename'] as String? ?? 'File';
          groupFileMeta = obj;
        }
      } catch (_) {}
    }

    final reactions = <Reaction>[];
    for (final r in (raw['reactions'] as List<dynamic>? ?? [])) {
      if (r is! Map) continue;
      if (r['emoji'] != null && r['forRecipient'] == null && r['forSender'] == null) {
        reactions.add(Reaction(userId: '${r['user']}', emoji: r['emoji'] as String?));
        continue;
      }
      final mineReaction = '${r['user']}' == me.id;
      final envJson = mineReaction ? r['forSender'] : r['forRecipient'];
      if (envJson is! Map) {
        reactions.add(Reaction(userId: '${r['user']}'));
        continue;
      }
      try {
        final env = SealedEnvelope.fromJson(Map<String, dynamic>.from(envJson));
        final sk = await storage.findSecretKeyForPublicKey(me.id, env.targetPublicKey);
        reactions.add(Reaction(userId: '${r['user']}', emoji: sk == null ? null : unsealMessage(env, sk)));
      } catch (_) {
        reactions.add(Reaction(userId: '${r['user']}'));
      }
    }

    AttachmentMeta? attachment;
    final attRaw = raw['attachment'];
    if (attRaw is Map) {
      attachment = AttachmentMeta.fromJson(
        Map<String, dynamic>.from(attRaw),
        groupKey: groupFileMeta?['key'] as String?,
        groupNonce: groupFileMeta?['nonce'] as String?,
      );
      if (text == null || text.isEmpty) {
        text = attachment.filename;
      }
    } else if (groupFileMeta != null && groupFileMeta['attachmentId'] != null) {
      attachment = AttachmentMeta(
        id: '${groupFileMeta['attachmentId']}',
        filename: groupFileMeta['filename'] as String? ?? 'file',
        mimetype: groupFileMeta['mimetype'] as String? ?? 'application/octet-stream',
        size: (groupFileMeta['size'] as num?)?.toInt() ?? 0,
        encryption: 'secretbox',
        groupKey: groupFileMeta['key'] as String?,
        groupNonce: groupFileMeta['nonce'] as String?,
        secretboxNonce: groupFileMeta['nonce'] as String?,
      );
    }

    String? replyToId;
    String? replyToText;
    final replyRaw = raw['replyTo'];
    if (replyRaw is Map) {
      replyToId = '${replyRaw['id'] ?? replyRaw['_id']}';
      replyToText = 'Reply';
    } else if (replyRaw != null) {
      replyToId = '$replyRaw';
      replyToText = 'Reply';
    }

    return ChatMessage(
      id: '${raw['id'] ?? raw['_id']}',
      from: from,
      to: raw['to']?.toString(),
      groupId: raw['group']?.toString(),
      text: text,
      createdAt: _parseDate(raw['createdAt']),
      deliveredAt: _parseDate(raw['deliveredAt']),
      readAt: _parseDate(raw['readAt']),
      editedAt: _parseDate(raw['editedAt']),
      reactions: reactions,
      replyToId: replyToId,
      replyToText: replyToText,
      kind: raw['kind'] as String? ?? (attachment != null ? 'file' : 'text'),
      attachment: attachment,
    );
  }

  Future<void> sendText(String draft) async {
    final conv = selected;
    final text = draft.trim();
    if (conv == null || text.isEmpty || sending) return;

    if (editing != null) {
      await editMessageText(editing!, text);
      return;
    }

    sending = true;
    notifyListeners();
    final replyId = replyTo?.id;
    try {
      if (conv.type == ConversationType.group) {
        final group = conv.group ?? groups.firstWhere((g) => g.id == conv.id);
        Map<String, dynamic> payload;
        if (group.isPublic) {
          payload = {'content': text};
        } else {
          payload = {'envelopes': await _sealGroupEnvelopes(text, group)};
        }
        if (replyId != null) payload['replyTo'] = replyId;
        final raw = await auth.api.sendGroupMessage(conv.id, payload);
        final msg = await decorate(raw);
        msg.text = text;
        messages = [...messages, msg];
      } else {
        final peer = conv.peer ?? users.cast<QcUser?>().firstWhere((u) => u?.id == conv.id, orElse: () => me) ?? me;
        final mySet = await storage.getCurrentKeySet(me.id);
        if (mySet.isEmpty || peer.publicKeys.isEmpty) {
          throw ApiException('Missing encryption keys for this conversation');
        }
        final forRecipient = sealMessage(text, pickRandom(peer.publicKeys));
        final forSender = sealMessage(text, pickRandom(mySet.map((k) => k.publicKey).toList()));
        final payload = <String, dynamic>{
          'to': conv.id,
          'forRecipient': forRecipient.toJson(),
          'forSender': forSender.toJson(),
        };
        if (replyId != null) payload['replyTo'] = replyId;
        final raw = await auth.api.sendMessage(payload);
        final msg = await decorate(raw);
        msg.text = text;
        messages = [...messages, msg];
      }
      clearComposerContext();
      await storage.setConversationActivity(
        me.id,
        conv.key,
        at: DateTime.now().toUtc().toIso8601String(),
        from: me.id,
      );
      _rebuildConversations();
    } on ApiException catch (e) {
      threadError = e.message;
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  Future<void> editMessageText(ChatMessage message, String text) async {
    final conv = selected;
    if (conv == null || text.trim().isEmpty) return;
    sending = true;
    notifyListeners();
    try {
      Map<String, dynamic> payload;
      if (conv.type == ConversationType.group) {
        final group = conv.group ?? groups.firstWhere((g) => g.id == conv.id);
        if (group.isPublic) {
          payload = {'content': text.trim()};
        } else {
          payload = {'envelopes': await _sealGroupEnvelopes(text.trim(), group)};
        }
      } else {
        final peer = conv.peer ?? me;
        final mySet = await storage.getCurrentKeySet(me.id);
        payload = {
          'forRecipient': sealMessage(text.trim(), pickRandom(peer.publicKeys)).toJson(),
          'forSender': sealMessage(text.trim(), pickRandom(mySet.map((k) => k.publicKey).toList())).toJson(),
        };
      }
      final raw = await auth.api.editMessage(message.id, payload);
      final updated = await decorate(raw);
      updated.text = text.trim();
      messages = messages.map((m) => m.id == updated.id ? updated : m).toList();
      clearComposerContext();
    } on ApiException catch (e) {
      threadError = e.message;
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  Future<void> deleteMessage(ChatMessage message, {bool forEveryone = false}) async {
    try {
      await auth.api.deleteMessage(message.id, forEveryone: forEveryone);
      if (forEveryone) {
        messages = messages.map((m) {
          if (m.id != message.id) return m;
          m.text = 'Message deleted';
          m.attachment = null;
          return m;
        }).toList();
      } else {
        messages = messages.where((m) => m.id != message.id).toList();
      }
      notifyListeners();
    } on ApiException catch (e) {
      threadError = e.message;
      notifyListeners();
    }
  }

  Future<void> sendAttachmentBytes({
    required Uint8List bytes,
    required String filename,
    required String mimetype,
  }) async {
    final conv = selected;
    if (conv == null || sending) return;
    sending = true;
    notifyListeners();
    try {
      if (conv.type == ConversationType.group) {
        final group = conv.group ?? groups.firstWhere((g) => g.id == conv.id);
        final sealed = secretboxSeal(bytes);
        final uploaded = await auth.api.uploadGroupAttachment(
          groupId: conv.id,
          filename: filename,
          mimetype: mimetype,
          sealed: sealed,
        );
        final plaintext = jsonEncode({
          '__qc': 1,
          'type': 'file',
          'attachmentId': '${uploaded['id']}',
          'key': sealed.key,
          'nonce': sealed.nonce,
          'filename': uploaded['filename'] ?? filename,
          'mimetype': uploaded['mimetype'] ?? mimetype,
          'size': uploaded['size'] ?? bytes.length,
        });
        final payload = <String, dynamic>{
          'kind': 'file',
          'attachmentId': '${uploaded['id']}',
        };
        if (group.isPublic) {
          payload['content'] = plaintext;
        } else {
          payload['envelopes'] = await _sealGroupEnvelopes(plaintext, group);
        }
        if (replyTo != null) payload['replyTo'] = replyTo!.id;
        final raw = await auth.api.sendGroupMessage(conv.id, payload);
        final msg = await decorate(raw);
        messages = [...messages, msg];
      } else {
        final peer = conv.peer ?? me;
        final mySet = await storage.getCurrentKeySet(me.id);
        if (mySet.isEmpty || peer.publicKeys.isEmpty) {
          throw ApiException('Missing encryption keys for this conversation');
        }
        final forRecipient = sealFileBytes(bytes, pickRandom(peer.publicKeys));
        final forSender = sealFileBytes(bytes, pickRandom(mySet.map((k) => k.publicKey).toList()));
        final uploaded = await auth.api.uploadDmAttachment(
          recipientId: conv.id,
          filename: filename,
          mimetype: mimetype,
          forRecipient: forRecipient,
          forSender: forSender,
        );
        final emptyRecipient = sealMessage('', pickRandom(peer.publicKeys));
        final emptySender = sealMessage('', pickRandom(mySet.map((k) => k.publicKey).toList()));
        final payload = <String, dynamic>{
          'to': conv.id,
          'forRecipient': emptyRecipient.toJson(),
          'forSender': emptySender.toJson(),
          'attachmentId': '${uploaded['id']}',
        };
        if (replyTo != null) payload['replyTo'] = replyTo!.id;
        final raw = await auth.api.sendMessage(payload);
        final msg = await decorate(raw);
        messages = [...messages, msg];
      }
      clearComposerContext();
      await storage.setConversationActivity(
        me.id,
        conv.key,
        at: DateTime.now().toUtc().toIso8601String(),
        from: me.id,
      );
      _rebuildConversations();
    } on ApiException catch (e) {
      threadError = e.message;
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  Future<void> sendGifFromUrl(String url) async {
    // Implemented in UI via download + sendAttachmentBytes.
  }

  Future<Uint8List?> decryptAttachment(ChatMessage message) async {
    final att = message.attachment;
    if (att == null) return null;
    final cipher = await auth.api.downloadAttachmentRaw(att.id);
    if (cipher == null) return null;

    if (att.encryption == 'secretbox' || (att.groupKey != null && att.groupNonce != null)) {
      final key = att.groupKey;
      final nonce = att.groupNonce ?? att.secretboxNonce;
      if (key == null || nonce == null) return null;
      return secretboxOpen(cipher, nonce, key);
    }

    final mySet = await storage.getCurrentKeySet(me.id);
    String? secretKey;
    String? nonce;
    String? ephemeral;

    if (att.forSenderTargetPublicKey != null && message.isMine(me.id)) {
      secretKey = await storage.findSecretKeyForPublicKey(me.id, att.forSenderTargetPublicKey!);
      nonce = att.forSenderNonce;
      ephemeral = att.forSenderEphemeralPublicKey;
    }
    if (secretKey == null && att.targetPublicKey != null) {
      secretKey = await storage.findSecretKeyForPublicKey(me.id, att.targetPublicKey!);
      nonce = att.nonce;
      ephemeral = att.ephemeralPublicKey;
    }
    if (secretKey == null || nonce == null || ephemeral == null) {
      // Try each local key against sender envelope then recipient envelope
      for (final k in mySet) {
        if (att.forSenderTargetPublicKey == k.publicKey) {
          secretKey = k.secretKey;
          nonce = att.forSenderNonce;
          ephemeral = att.forSenderEphemeralPublicKey;
          break;
        }
        if (att.targetPublicKey == k.publicKey) {
          secretKey = k.secretKey;
          nonce = att.nonce;
          ephemeral = att.ephemeralPublicKey;
          break;
        }
      }
    }
    if (secretKey == null || nonce == null || ephemeral == null) return null;
    return unsealFileBytes(cipher, nonce: nonce, ephemeralPublicKey: ephemeral, myPrivateKeyHex: secretKey);
  }

  Future<void> postStory(Uint8List bytes, {String filename = 'story.jpg', String mimetype = 'image/jpeg'}) async {
    await auth.api.createStory(bytes: bytes, filename: filename, mimetype: mimetype);
    await refreshStories();
  }

  Future<void> refreshGroup(String groupId) async {
    final g = await auth.api.getGroup(groupId);
    groups = groups.map((x) => x.id == g.id ? g : x).toList();
    if (selected?.id == groupId) {
      selected = Conversation(
        key: selected!.key,
        type: ConversationType.group,
        id: g.id,
        title: g.name,
        subtitle: selected!.subtitle,
        group: g,
        unread: selected!.unread,
        sortAt: selected!.sortAt,
      );
    }
    _rebuildConversations();
  }

  Future<List<Map<String, dynamic>>> _sealGroupEnvelopes(String plaintext, QcGroup group) async {
    final envelopes = <Map<String, dynamic>>[];
    final mySet = await storage.getCurrentKeySet(me.id);
    for (final member in group.members) {
      String? publicKey;
      if (member.id == me.id) {
        if (mySet.isEmpty) throw ApiException('Missing your encryption keys');
        publicKey = pickRandom(mySet.map((k) => k.publicKey).toList());
      } else {
        if (member.publicKeys.isEmpty) {
          throw ApiException('Missing encryption keys for ${member.username}');
        }
        publicKey = pickRandom(member.publicKeys);
      }
      final sealed = sealMessage(plaintext, publicKey);
      envelopes.add({'user': member.id, ...sealed.toJson()});
    }
    return envelopes;
  }

  void onComposerChanged(String value) {
    final conv = selected;
    if (conv == null) return;
    if (conv.type == ConversationType.dm) {
      socket.typingStart(to: conv.id);
    } else {
      socket.typingStart(groupId: conv.id);
    }
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 2), () {
      if (conv.type == ConversationType.dm) {
        socket.typingStop(to: conv.id);
      } else {
        socket.typingStop(groupId: conv.id);
      }
    });
  }

  Future<bool> react(ChatMessage message, String emoji) async {
    final conv = selected;
    if (conv == null) return false;
    try {
      final mySet = await storage.getCurrentKeySet(me.id);
      if (mySet.isEmpty) {
        threadError = 'Missing encryption keys for reactions';
        notifyListeners();
        return false;
      }

      List<String> recipientKeys = [];
      if (conv.type == ConversationType.group) {
        final group = conv.group ?? groups.cast<QcGroup?>().firstWhere((g) => g?.id == conv.id, orElse: () => null);
        if (group == null) return false;
        // Seal reaction for the message author so they can read it.
        final authorId = message.from;
        QcUser? author;
        for (final m in group.members) {
          if (m.id == authorId) {
            author = m;
            break;
          }
        }
        author ??= users.cast<QcUser?>().firstWhere((u) => u?.id == authorId, orElse: () => null);
        recipientKeys = author?.publicKeys ?? [];
        if (recipientKeys.isEmpty && authorId == me.id) {
          recipientKeys = mySet.map((k) => k.publicKey).toList();
        }
      } else {
        final peer = conv.peer ?? users.cast<QcUser?>().firstWhere((u) => u?.id == conv.id, orElse: () => me) ?? me;
        recipientKeys = peer.publicKeys;
        if (recipientKeys.isEmpty && conv.isSelfChat) {
          recipientKeys = mySet.map((k) => k.publicKey).toList();
        }
      }

      if (recipientKeys.isEmpty) {
        threadError = 'Missing encryption keys for reactions';
        notifyListeners();
        return false;
      }

      final raw = await auth.api.reactToMessage(message.id, {
        'forRecipient': sealMessage(emoji, pickRandom(recipientKeys)).toJson(),
        'forSender': sealMessage(emoji, pickRandom(mySet.map((k) => k.publicKey).toList())).toJson(),
      });
      final updated = await decorate(raw);
      messages = messages.map((m) => m.id == updated.id ? updated : m).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      threadError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      threadError = 'Could not add reaction';
      notifyListeners();
      return false;
    }
  }

  Future<QcGroup?> createGroup(String name, List<String> memberIds) async {
    try {
      final group = await auth.api.createGroup(name: name, memberIds: memberIds);
      groups = [group, ...groups];
      _rebuildConversations();
      return group;
    } on ApiException catch (e) {
      threadError = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<void> _noteActivity(Map<String, dynamic> raw) async {
    final group = raw['group']?.toString();
    final from = raw['from']?.toString();
    final to = raw['to']?.toString();
    final at = raw['createdAt'] as String? ?? DateTime.now().toUtc().toIso8601String();
    String key;
    if (group != null && group.isNotEmpty && group != 'null') {
      key = storage.conversationKeyForGroup(group);
    } else {
      final other = from == me.id ? to : from;
      if (other == null) return;
      key = storage.conversationKeyForUser(other);
    }
    await storage.setConversationActivity(me.id, key, at: at, from: from);
  }

  bool _messageBelongs(ChatMessage msg, Conversation conv) {
    if (conv.type == ConversationType.group) {
      return msg.groupId == conv.id;
    }
    return (msg.from == me.id && msg.to == conv.id) || (msg.from == conv.id && (msg.to == me.id || msg.to == null));
  }

  Future<void> _pollSync() async {
    try {
      final rows = await auth.api.syncMessages();
      for (final row in rows) {
        await _noteActivity(row);
      }
      _rebuildConversations();
      await _refreshFriendRequests();
      if (selected != null && rows.isNotEmpty) {
        await open(selected!);
      }
    } catch (_) {}
  }

  DateTime? _parseDate(dynamic v) {
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }

  String displayName(String userId) {
    if (userId == me.id) return 'You';
    for (final u in users) {
      if (u.id == userId) return u.title;
    }
    for (final g in groups) {
      for (final m in g.members) {
        if (m.id == userId) return m.title;
      }
    }
    return 'Member';
  }
}
