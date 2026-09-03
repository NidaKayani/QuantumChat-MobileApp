import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../state/chat_controller.dart';
import '../theme/qc_theme.dart';

void showEditHistorySheet({
  required BuildContext context,
  required ChatMessage message,
  required QcColors colors,
  required ChatController chat,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: colors.surface,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final fmt = DateFormat('MMM d, yyyy  h:mm a');
      final entries = message.editHistory;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit history',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Current: ${message.text ?? 'Unable to decrypt'}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 14),
                if (entries.isEmpty)
                  Text('No previous versions available.', style: TextStyle(color: colors.textMuted))
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => Divider(color: colors.border.withValues(alpha: 0.5), height: 1),
                      itemBuilder: (_, i) {
                        final e = entries[entries.length - 1 - i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fmt.format(e.editedAt.toLocal()),
                                style: TextStyle(color: colors.accentCyan, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                e.text ?? 'Unable to decrypt',
                                style: TextStyle(
                                  color: e.text != null ? colors.textPrimary : colors.textMuted,
                                  fontStyle: e.text != null ? FontStyle.normal : FontStyle.italic,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
