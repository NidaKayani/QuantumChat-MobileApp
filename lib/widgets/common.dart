import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/qc_theme.dart';

const _avatarPalette = [
  Color(0xFF2563EB),
  Color(0xFF7C3AED),
  Color(0xFF0D9488),
  Color(0xFFD97706),
  Color(0xFFDB2777),
  Color(0xFF059669),
  Color(0xFFDC2626),
  Color(0xFF0284C7),
  Color(0xFF4F46E5),
  Color(0xFFCA8A04),
];

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.userId,
    this.hasAvatar = false,
    this.size = 44,
    this.online = false,
    this.imageBytes,
  });

  final String name;
  final String? userId;
  final bool hasAvatar;
  final double size;
  final bool online;
  final ImageProvider? imageBytes;

  @override
  Widget build(BuildContext context) {
    final colors = QcColors.of(
      Theme.of(context).brightness == Brightness.light ? QcThemeId.light : QcThemeId.dark,
    );
    // Use inherited colors via Theme instead when possible.
    final idx = (userId ?? name).codeUnits.fold<int>(0, (a, b) => a + b) % _avatarPalette.length;
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\s+')).take(2).map((p) => p[0].toUpperCase()).join();

    Widget inner;
    if (imageBytes != null) {
      inner = ClipOval(
        child: Image(image: imageBytes!, width: size, height: size, fit: BoxFit.cover),
      );
    } else {
      inner = CircleAvatar(
        radius: size / 2,
        backgroundColor: _avatarPalette[idx],
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.34,
          ),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          inner,
          if (online)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.surface, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class QcPrimaryButton extends StatelessWidget {
  const QcPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(label),
      ),
    );
  }
}

int passwordScore(String password) {
  var score = 0;
  if (password.length >= 8) score++;
  if (password.length >= 12) score++;
  if (RegExp(r'[A-Z]').hasMatch(password) && RegExp(r'[a-z]').hasMatch(password)) score++;
  if (RegExp(r'\d').hasMatch(password)) score++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;
  return score.clamp(0, 4);
}

class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password, required this.colors});
  final String password;
  final QcColors colors;

  @override
  Widget build(BuildContext context) {
    final score = passwordScore(password);
    final labels = ['Too weak', 'Weak', 'Okay', 'Strong', 'Excellent'];
    final barColors = [
      colors.error,
      const Color(0xFFF59E0B),
      const Color(0xFFFBBF24),
      colors.success,
      colors.accentCyan,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i == 3 ? 0 : 4),
                decoration: BoxDecoration(
                  color: i < score ? barColors[score] : colors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          labels[score],
          style: TextStyle(color: barColors[score], fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

String formatLastSeen(DateTime? at, {bool online = false}) {
  if (online) return 'online';
  if (at == null) return 'never seen';
  final diff = DateTime.now().difference(at.toLocal());
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

String formatMessageTime(DateTime? at) {
  if (at == null) return '';
  final local = at.toLocal();
  final now = DateTime.now();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  if (local.year == now.year && local.month == now.month && local.day == now.day) {
    return '$hh:$mm';
  }
  return '${local.month}/${local.day} $hh:$mm';
}

QcUser? userFromConversation(Conversation c) => c.peer;
