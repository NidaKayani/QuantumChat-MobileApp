import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/chat_home_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/unlock_keys_screen.dart';
import 'state/auth_controller.dart';
import 'state/theme_controller.dart';
import 'theme/qc_theme.dart';

class QuantumChatApp extends StatelessWidget {
  const QuantumChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    return MaterialApp(
      title: 'QuantumChat',
      debugShowCheckedModeBanner: false,
      theme: QcTheme.material(theme.colors),
      home: const _RootGate(),
    );
  }
}

class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (!auth.ready) {
      return Scaffold(
        backgroundColor: context.watch<ThemeController>().colors.body,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (auth.user == null) return const LandingScreen();
    if (!auth.hasLocalKeyring) return const UnlockKeysScreen();
    return const ChatHomeScreen();
  }
}
