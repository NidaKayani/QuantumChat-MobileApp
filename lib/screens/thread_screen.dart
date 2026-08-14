import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/chat_controller.dart';
import '../state/theme_controller.dart';
import '../widgets/common.dart';

class ThreadScreen extends StatefulWidget {
  const ThreadScreen({super.key});

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<ThreadScreen> {
  final composer = TextEditingController();
  final scroll = ScrollController();

  @override
  void dispose() {
    composer.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = composer.text;
    composer.clear();
    await context.read<ChatController>().sendText(text);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (scroll.hasClients) {
      scroll.animateTo(
        scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();
    final colors = context.watch<ThemeController>().colors;
    final conv = chat.selected;
    if (conv == null) {
      return const Scaffold(body: Center(child: Text('No conversation')));
    }
    final typingName = chat.typingFrom == null ? null : chat.displayName(chat.typingFrom!);

    return Scaffold(
      backgroundColor: colors.chat,
      appBar: AppBar(
        title: Row(
          children: [
            UserAvatar(
              name: conv.title,
              userId: conv.id,
              hasAvatar: conv.peer?.hasAvatar == true || conv.group?.hasPhoto == true,
              online: conv.online,
              size: 36,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(conv.title, overflow: TextOverflow.ellipsis),
                  Text(
                    typingName != null
                        ? '$typingName is typing…'
                        : conv.type == ConversationType.group
                            ? (conv.subtitle ?? 'Group')
                            : (conv.online ? 'online' : formatLastSeen(conv.peer?.lastLoginAt)),
                    style: TextStyle(
                      color: typingName != null ? colors.accentCyan : colors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (chat.threadError != null)
            Material(
              color: colors.error.withValues(alpha: 0.12),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(chat.threadError!, style: TextStyle(color: colors.error)),
              ),
            ),
          Expanded(
            child: chat.loadingThread
                ? const Center(child: CircularProgressIndicator())
                : chat.messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet. Say hello — it is sealed before it leaves this phone.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.textMuted),
                        ),
                      )
                    : ListView.builder(
                        controller: scroll,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                        itemCount: chat.messages.length,
                        itemBuilder: (context, i) {
                          final m = chat.messages[i];
                          final mine = m.isMine(chat.me.id);
                          final showName = conv.type == ConversationType.group && !mine;
                          return Align(
                            alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                            child: GestureDetector(
                              onLongPress: () => _reactSheet(m),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                                  decoration: BoxDecoration(
                                    color: mine ? colors.bubbleMine : colors.bubbleTheirs,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(mine ? 16 : 4),
                                      bottomRight: Radius.circular(mine ? 4 : 16),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (showName)
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            chat.displayName(m.from),
                                            style: TextStyle(
                                              color: colors.accentCyan,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          m.text ?? 'Unable to decrypt',
                                          style: TextStyle(
                                            color: m.text == null
                                                ? (mine ? colors.bubbleMineFg.withValues(alpha: 0.7) : colors.textMuted)
                                                : (mine ? colors.bubbleMineFg : colors.bubbleTheirsFg),
                                            fontStyle: m.text == null ? FontStyle.italic : FontStyle.normal,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (m.reactions.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(right: 6),
                                              child: Text(
                                                m.reactions.map((r) => r.emoji).whereType<String>().join(' '),
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                            ),
                                          Text(
                                            formatMessageTime(m.createdAt),
                                            style: TextStyle(
                                              color: mine ? colors.bubbleMineFg.withValues(alpha: 0.78) : colors.textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                          if (mine) ...[
                                            const SizedBox(width: 4),
                                            Icon(
                                              m.readAt != null
                                                  ? Icons.done_all
                                                  : m.deliveredAt != null
                                                      ? Icons.done_all
                                                      : Icons.done,
                                              size: 14,
                                              color: m.readAt != null
                                                  ? colors.accentCyan
                                                  : (mine ? colors.bubbleMineFg.withValues(alpha: 0.78) : colors.textMuted),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Container(
              color: colors.surface,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: composer,
                      minLines: 1,
                      maxLines: 5,
                      onChanged: chat.onComposerChanged,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Encrypted message…',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: colors.accent,
                    child: IconButton(
                      onPressed: chat.sending ? null : _send,
                      icon: chat.sending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reactSheet(ChatMessage message) async {
    const emojis = ['👍', '❤️', '😂', '😮', '😢', '🔥'];
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.read<ThemeController>().colors.surface,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: emojis
                  .map(
                    (e) => InkWell(
                      onTap: () => Navigator.pop(ctx, e),
                      child: Text(e, style: const TextStyle(fontSize: 28)),
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
    if (picked != null && mounted) {
      await context.read<ChatController>().react(message, picked);
    }
  }
}
