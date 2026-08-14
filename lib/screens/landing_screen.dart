import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/theme_controller.dart';
import '../theme/qc_theme.dart';
import '../widgets/brand_logo.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeController>().colors;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: colors.body,
          gradient: RadialGradient(
            center: const Alignment(-0.6, -0.7),
            radius: 1.1,
            colors: [
              colors.accent.withValues(alpha: 0.16),
              colors.body,
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              Row(
                children: [
                  const BrandLogo(size: 36),
                  const SizedBox(width: 10),
                  Text.rich(
                    TextSpan(
                      text: 'Quantum',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                      children: [
                        TextSpan(text: 'Chat', style: TextStyle(color: colors.accentCyan)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => context.read<ThemeController>().cycle(),
                    icon: Icon(
                      colors.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              const BrandLogo(size: 64),
              const SizedBox(height: 20),
              Text(
                'Private messaging that stays on your device',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'End-to-end sealed with X25519 and NaCl box encryption. Your keys never leave this phone — even we can\'t read your chats.',
                style: TextStyle(color: colors.textSecondary, fontSize: 16, height: 1.45),
              ),
              const SizedBox(height: 28),
              QcCta(
                label: 'Start encrypted chat',
                filled: true,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
              ),
              const SizedBox(height: 12),
              QcCta(
                label: 'Sign in',
                filled: false,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
              ),
              const SizedBox(height: 36),
              _Feature(
                colors: colors,
                icon: Icons.lock_outline,
                title: 'Client-side encryption',
                copy: 'Keys are generated and used only on your phone. The server never sees private keys or plaintext.',
              ),
              _Feature(
                colors: colors,
                icon: Icons.key_outlined,
                title: 'Portable key backups',
                copy: 'Export a simple keys.txt file to restore your keyring on another device.',
              ),
              _Feature(
                colors: colors,
                icon: Icons.bolt_outlined,
                title: 'Realtime delivery',
                copy: 'Messages travel over WebSockets, then decrypt locally against your key pool.',
              ),
              const SizedBox(height: 12),
              Text(
                '01  Create your account\n02  Save your keyring\n03  Start chatting',
                style: TextStyle(color: colors.textMuted, height: 1.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QcCta extends StatelessWidget {
  const QcCta({super.key, required this.label, required this.onTap, required this.filled});
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeController>().colors;
    return SizedBox(
      height: 52,
      child: filled
          ? ElevatedButton(onPressed: onTap, child: Text(label))
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.textPrimary,
                side: BorderSide(color: colors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(label),
            ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.colors, required this.icon, required this.title, required this.copy});
  final QcColors colors;
  final IconData icon;
  final String title;
  final String copy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.accentMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colors.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(copy, style: TextStyle(color: colors.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
