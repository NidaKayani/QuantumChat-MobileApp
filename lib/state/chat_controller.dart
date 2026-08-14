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
  Conversation? selected;
  String filter = 'all';
  String search = '';
  bool loadingInbox = false;
  bool loadingThread = false;
  bool sending = false;
  String? threadError;
  String? typingFrom;
  final Set<String> onlineUserIds = {};
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
      kind: raw['kind'] as String? ?? 'text',
    );
  }

  Future<void> sendText(String draft) async {
    final conv = selected;
    final text = draft.trim();
    if (conv == null || text.isEmpty || sending) return;
    sending = true;
    notifyListeners();
    try {
      if (conv.type == ConversationType.group) {
        final group = conv.group ?? groups.firstWhere((g) => g.id == conv.id);
        Map<String, dynamic> payload;
        if (group.isPublic) {
          payload = {'content': text};
        } else {
          payload = {'envelopes': await _sealGroupEnvelopes(text, group)};
        }
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
        final raw = await auth.api.sendMessage({
          'to': conv.id,
          'forRecipient': forRecipient.toJson(),
          'forSender': forSender.toJson(),
        });
        final msg = await decorate(raw);
        msg.text = text;
        messages = [...messages, msg];
      }
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

  Future<void> react(ChatMessage message, String emoji) async {
    final conv = selected;
    if (conv == null) return;
    try {
      final mySet = await storage.getCurrentKeySet(me.id);
      List<String> recipientKeys = [];
      if (conv.type == ConversationType.group) {
        final group = conv.group;
        final targetId = message.from == me.id
            ? group?.members.map((m) => m.id).firstWhere((id) => id != me.id, orElse: () => me.id)
            : message.from;
        final member = group?.members.cast<QcUser?>().firstWhere((m) => m?.id == targetId, orElse: () => null);
        recipientKeys = member?.publicKeys ?? [];
      } else {
        recipientKeys = conv.peer?.publicKeys ?? [];
      }
      if (mySet.isEmpty || recipientKeys.isEmpty) return;
      final raw = await auth.api.reactToMessage(message.id, {
        'forRecipient': sealMessage(emoji, pickRandom(recipientKeys)).toJson(),
        'forSender': sealMessage(emoji, pickRandom(mySet.map((k) => k.publicKey).toList())).toJson(),
      });
      final updated = await decorate(raw);
      messages = messages.map((m) => m.id == updated.id ? updated : m).toList();
      notifyListeners();
    } catch (_) {}
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
