import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/qc_theme.dart';

class MentionOverlay extends StatelessWidget {
  const MentionOverlay({
    super.key,
    required this.link,
    required this.members,
    required this.colors,
    required this.onSelect,
  });

  final LayerLink link;
  final List<QcUser> members;
  final QcColors colors;
  final ValueChanged<QcUser> onSelect;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      width: 220,
      child: CompositedTransformFollower(
        link: link,
        showWhenUnlinked: false,
        offset: const Offset(0, -48),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          color: colors.elevated,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: members.length,
              itemBuilder: (context, i) {
                final m = members[i];
                return ListTile(
                  dense: true,
                  title: Text(
                    '@${m.username}',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                  subtitle: Text(
                    m.displayName,
                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                  ),
                  onTap: () => onSelect(m),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
