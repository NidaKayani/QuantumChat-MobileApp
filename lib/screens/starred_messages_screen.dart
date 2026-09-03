import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/chat_controller.dart';
import '../state/theme_controller.dart';
import '../widgets/common.dart';

/// Screen listing all starred / bookmarked messages.
/// Stars are stored locally since the backend has no star endpoint yet.
class StarredMessagesScreen extends StatelessWidget {
  const StarredMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();
    final colors = context.watch<ThemeController>().colors;
    final starred = chat.messages.where((m) => m.isStarred).toList();

    return Scaffold(
      backgroundColor: colors.body,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: const Text('Starred Messages'),
      ),
      body: starred.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_border, size: 64, color: colors.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    'No starred messages',
                    style: TextStyle(color: colors.textMuted, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Long-press a message and tap Star to save it here.',
                    style: TextStyle(color: colors.textMuted, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: starred.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: colors.border),
              itemBuilder: (ctx, i) {
                final m = starred[i];
                final senderName = chat.displayName(m.from);
                return ListTile(
                  leading: Icon(Icons.star, color: colors.accentCyan),
                  title: Text(
                    m.text ?? '📎 Attachment',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.textPrimary),
                  ),
                  subtitle: Text(
                    '$senderName  •  ${formatMessageTime(m.createdAt)}',
                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.star, color: colors.accentCyan),
                    tooltip: 'Unstar',
                    onPressed: () {
                      m.isStarred = false;
                      chat.notify();
                    },
                  ),
                );
              },
            ),
    );
  }
}
