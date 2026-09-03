import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../crypto/qc_crypto.dart';
import '../models/models.dart';
import '../state/auth_controller.dart';
import '../state/chat_controller.dart';
import '../theme/qc_theme.dart';
import 'common.dart';

/// Bottom sheet that shows conversations to forward a message to.
Future<bool?> showForwardSheet({
  required BuildContext context,
  required ChatMessage message,
  required QcColors colors,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: colors.surface,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _ForwardSheetBody(message: message, colors: colors),
  );
}

class _ForwardSheetBody extends StatefulWidget {
  const _ForwardSheetBody({required this.message, required this.colors});
  final ChatMessage message;
  final QcColors colors;

  @override
  State<_ForwardSheetBody> createState() => _ForwardSheetBodyState();
}

class _ForwardSheetBodyState extends State<_ForwardSheetBody> {
  final _search = TextEditingController();
  String _query = '';
  bool _sending = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Conversation> _filtered(List<Conversation> all) {
    if (_query.trim().isEmpty) return all;
    final q = _query.trim().toLowerCase();
    return all.where((c) => c.title.toLowerCase().contains(q)).toList();
  }

  Future<void> _forward(Conversation target) async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      final auth = context.read<AuthController>();
      final chat = context.read<ChatController>();
      final me = chat.me;

      if (target.type == ConversationType.group) {
        final group = target.group ?? chat.groups.firstWhere((g) => g.id == target.id);
        Map<String, dynamic> payload;
        if (group.isPublic) {
          payload = {
            'content': widget.message.text ?? '📎 Attachment',
            'forwardedFrom': {'messageId': widget.message.id, 'username': me.username},
          };
        } else {
          final plaintext = widget.message.text ?? '📎 Attachment';
          payload = {
            'envelopes': await chat.sealGroupEnvelopesPublic(plaintext, group),
            'forwardedFrom': {'messageId': widget.message.id, 'username': me.username},
          };
        }
        await auth.api.sendGroupMessage(target.id, payload);
      } else {
        final peer = target.peer ?? chat.users.cast<QcUser?>().firstWhere(
              (u) => u?.id == target.id,
              orElse: () => me,
            ) ?? me;
        final mySet = await chat.storage.getCurrentKeySet(me.id);
        if (mySet.isEmpty || peer.publicKeys.isEmpty) {
          throw ApiException('Missing encryption keys');
        }
        final text = widget.message.text ?? '📎 Attachment';
        final forRecipient = sealMessage(text, pickRandom(peer.publicKeys));
        final forSender = sealMessage(text, pickRandom(mySet.map((k) => k.publicKey).toList()));
        await auth.api.sendMessage({
          'to': target.id,
          'forRecipient': forRecipient.toJson(),
          'forSender': forSender.toJson(),
          'forwardedFrom': {'messageId': widget.message.id, 'username': me.username},
        });
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Forward failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();
    final conversations = _filtered(chat.conversations);
    final colors = widget.colors;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (ctx, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Search conversations…',
                prefixIcon: Icon(Icons.search, color: colors.textMuted),
                filled: true,
                fillColor: colors.elevated,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          if (_sending)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            ),
          Expanded(
            child: ListView.builder(
              controller: scroll,
              itemCount: conversations.length,
              itemBuilder: (ctx, i) {
                final c = conversations[i];
                return ListTile(
                  leading: UserAvatar(
                    name: c.title,
                    userId: c.id,
                    hasAvatar: c.peer?.hasAvatar == true || c.group?.hasPhoto == true,
                    isGroup: c.type == ConversationType.group,
                    size: 40,
                  ),
                  title: Text(c.title, style: TextStyle(color: colors.textPrimary)),
                  subtitle: c.subtitle != null
                      ? Text(c.subtitle!, style: TextStyle(color: colors.textMuted, fontSize: 12))
                      : null,
                  onTap: _sending ? null : () => _forward(c),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
