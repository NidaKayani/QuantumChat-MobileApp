import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../theme/qc_theme.dart';

void showMessageInfoSheet({
  required BuildContext context,
  required ChatMessage message,
  required QcColors colors,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: colors.surface,
    showDragHandle: true,
    builder: (ctx) {
      final fmt = DateFormat('MMM d, yyyy  h:mm:ss a');
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Message info',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              if (message.createdAt != null)
                _InfoRow(label: 'Sent', value: fmt.format(message.createdAt!.toLocal()), colors: colors),
              if (message.deliveredAt != null)
                _InfoRow(label: 'Delivered', value: fmt.format(message.deliveredAt!.toLocal()), colors: colors),
              if (message.readAt != null)
                _InfoRow(label: 'Read', value: fmt.format(message.readAt!.toLocal()), colors: colors),
              if (message.editedAt != null)
                _InfoRow(label: 'Edited', value: fmt.format(message.editedAt!.toLocal()), colors: colors),
            ],
          ),
        ),
      );
    },
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, required this.colors});
  final String label;
  final String value;
  final QcColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: colors.textMuted, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
