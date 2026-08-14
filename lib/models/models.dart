class PrivacySettings {
  const PrivacySettings({
    this.lastSeen = 'everyone',
    this.online = 'everyone',
    this.readReceipts = 'everyone',
    this.whoCanMessage = 'everyone',
    this.discoverable = 'everyone',
    this.story = 'everyone',
  });

  final String lastSeen;
  final String online;
  final String readReceipts;
  final String whoCanMessage;
  final String discoverable;
  final String story;

  factory PrivacySettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PrivacySettings();
    var receipts = json['readReceipts'];
    if (receipts is bool) receipts = receipts ? 'everyone' : 'nobody';
    return PrivacySettings(
      lastSeen: json['lastSeen'] as String? ?? 'everyone',
      online: json['online'] as String? ?? 'everyone',
      readReceipts: receipts as String? ?? 'everyone',
      whoCanMessage: json['whoCanMessage'] as String? ?? 'everyone',
      discoverable: json['discoverable'] as String? ?? 'everyone',
      story: json['story'] as String? ?? 'everyone',
    );
  }
}

class QcUser {
  const QcUser({
    required this.id,
    required this.username,
    this.displayName = '',
    this.bio = '',
    this.email,
    this.phone = '',
    this.publicKeys = const [],
    this.lastLoginAt,
    this.hasAvatar = false,
    this.emailVerified = false,
    this.privacy = const PrivacySettings(),
    this.isSystemUser = false,
    this.systemRole,
    this.verified = false,
    this.blockedUsers = const [],
    this.friends = const [],
    this.totpEnabled = false,
  });

  final String id;
  final String username;
  final String displayName;
  final String bio;
  final String? email;
  final String phone;
  final List<String> publicKeys;
  final DateTime? lastLoginAt;
  final bool hasAvatar;
  final bool emailVerified;
  final PrivacySettings privacy;
  final bool isSystemUser;
  final String? systemRole;
  final bool verified;
  final List<String> blockedUsers;
  final List<String> friends;
  final bool totpEnabled;

  String get title => displayName.isNotEmpty ? displayName : username;

  bool get isQuantumAi => systemRole == 'quantum_ai';

  factory QcUser.fromJson(Map<String, dynamic> json) {
    DateTime? lastLogin;
    final rawLogin = json['lastLoginAt'];
    if (rawLogin is String && rawLogin.isNotEmpty) {
      lastLogin = DateTime.tryParse(rawLogin);
    }
    return QcUser(
      id: '${json['id'] ?? json['_id']}',
      username: json['username'] as String? ?? 'user',
      displayName: json['displayName'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String? ?? '',
      publicKeys: (json['publicKeys'] as List<dynamic>? ?? [])
          .map((k) => k.toString().toLowerCase())
          .toList(),
      lastLoginAt: lastLogin,
      hasAvatar: json['hasAvatar'] == true,
      emailVerified: json['emailVerified'] == true,
      privacy: PrivacySettings.fromJson(json['privacy'] as Map<String, dynamic>?),
      isSystemUser: json['isSystemUser'] == true,
      systemRole: json['systemRole'] as String?,
      verified: json['verified'] == true,
      blockedUsers: (json['blockedUsers'] as List<dynamic>? ?? []).map((e) => '$e').toList(),
      friends: (json['friends'] as List<dynamic>? ?? []).map((e) => '$e').toList(),
      totpEnabled: json['totpEnabled'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'displayName': displayName,
        'bio': bio,
        'email': email,
        'phone': phone,
        'publicKeys': publicKeys,
        'lastLoginAt': lastLoginAt?.toIso8601String(),
        'hasAvatar': hasAvatar,
        'emailVerified': emailVerified,
        'privacy': {
          'lastSeen': privacy.lastSeen,
          'online': privacy.online,
          'readReceipts': privacy.readReceipts,
          'whoCanMessage': privacy.whoCanMessage,
          'discoverable': privacy.discoverable,
          'story': privacy.story,
        },
        'isSystemUser': isSystemUser,
        'systemRole': systemRole,
        'verified': verified,
        'blockedUsers': blockedUsers,
        'friends': friends,
        'totpEnabled': totpEnabled,
      };

  QcUser copyWith({
    String? displayName,
    String? bio,
    List<String>? publicKeys,
    bool? hasAvatar,
    bool? emailVerified,
    PrivacySettings? privacy,
  }) {
    return QcUser(
      id: id,
      username: username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      email: email,
      phone: phone,
      publicKeys: publicKeys ?? this.publicKeys,
      lastLoginAt: lastLoginAt,
      hasAvatar: hasAvatar ?? this.hasAvatar,
      emailVerified: emailVerified ?? this.emailVerified,
      privacy: privacy ?? this.privacy,
      isSystemUser: isSystemUser,
      systemRole: systemRole,
      verified: verified,
      blockedUsers: blockedUsers,
      friends: friends,
      totpEnabled: totpEnabled,
    );
  }
}

class QcGroup {
  const QcGroup({
    required this.id,
    required this.name,
    this.description = '',
    this.members = const [],
    this.admins = const [],
    this.hasPhoto = false,
    this.visibility = 'private',
    this.updatedAt,
    this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final List<QcUser> members;
  final List<String> admins;
  final bool hasPhoto;
  final String visibility;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  bool get isPublic => visibility == 'public';

  factory QcGroup.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic v) => v is String ? DateTime.tryParse(v) : null;
    return QcGroup(
      id: '${json['id'] ?? json['_id']}',
      name: json['name'] as String? ?? 'Group',
      description: json['description'] as String? ?? '',
      members: (json['members'] as List<dynamic>? ?? []).map((m) {
        if (m is Map<String, dynamic>) return QcUser.fromJson(m);
        return QcUser(id: '$m', username: 'member');
      }).toList(),
      admins: (json['admins'] as List<dynamic>? ?? []).map((e) => '$e').toList(),
      hasPhoto: json['hasPhoto'] == true,
      visibility: json['visibility'] as String? ?? 'private',
      updatedAt: parse(json['updatedAt']),
      createdAt: parse(json['createdAt']),
    );
  }
}

class Reaction {
  const Reaction({required this.userId, this.emoji});
  final String userId;
  final String? emoji;
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.from,
    this.to,
    this.groupId,
    this.text,
    this.createdAt,
    this.deliveredAt,
    this.readAt,
    this.editedAt,
    this.pending = false,
    this.reactions = const [],
    this.replyToText,
    this.kind = 'text',
  });

  final String id;
  final String from;
  final String? to;
  final String? groupId;
  String? text;
  final DateTime? createdAt;
  DateTime? deliveredAt;
  DateTime? readAt;
  final DateTime? editedAt;
  final bool pending;
  final List<Reaction> reactions;
  final String? replyToText;
  final String kind;

  bool isMine(String myId) => from == myId;
}

enum ConversationType { dm, group }

class Conversation {
  Conversation({
    required this.key,
    required this.type,
    required this.id,
    required this.title,
    this.subtitle,
    this.peer,
    this.group,
    this.unread = false,
    this.sortAt = '',
    this.online = false,
    this.isSelfChat = false,
    this.muted = false,
  });

  final String key;
  final ConversationType type;
  final String id;
  final String title;
  final String? subtitle;
  final QcUser? peer;
  final QcGroup? group;
  bool unread;
  String sortAt;
  bool online;
  final bool isSelfChat;
  bool muted;
}

class ApiException implements Exception {
  ApiException(this.message, {this.status});
  final String message;
  final int? status;
  @override
  String toString() => message;
}
