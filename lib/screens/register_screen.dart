import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../crypto/qc_crypto.dart';
import '../state/auth_controller.dart';
import '../state/theme_controller.dart';
import '../widgets/brand_logo.dart';
import '../widgets/common.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final username = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool showPassword = false;
  bool showBackup = false;
  bool keysShared = false;

  @override
  void dispose() {
    username.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthController>();
    if (username.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usernames must be at least 3 characters.')));
      return;
    }
    if (password.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords must be at least 8 characters.')));
      return;
    }
    final ok = await auth.register(
      username: username.text.trim(),
      email: email.text.trim(),
      password: password.text,
    );
    if (ok) setState(() => showBackup = true);
  }

  Future<void> _shareKeys() async {
    final auth = context.read<AuthController>();
    final keys = auth.lastGeneratedKeySet;
    final user = auth.user;
    if (keys == null || user == null) return;
    final content = formatKeyFile(
      username: user.username,
      email: user.email ?? email.text.trim(),
      secretKeys: keys.map((k) => k.secretKey).toList(),
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/keys.txt');
    await file.writeAsString(content);
    await Share.shareXFiles([XFile(file.path, mimeType: 'text/plain')], text: 'QuantumChat private keys');
    setState(() => keysShared = true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final colors = context.watch<ThemeController>().colors;

    if (showBackup && auth.user != null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Icon(Icons.warning_amber_rounded, color: colors.error, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Backup your encryption keys',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Text(
                  'If you lose these keys, you will lose access to all your messages. They cannot be recovered by the server.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.error, height: 1.4),
                ),
                const Spacer(),
                QcPrimaryButton(
                  label: keysShared ? 'Continue to chat' : 'Save keys.txt',
                  onPressed: keysShared ? () => Navigator.of(context).popUntil((r) => r.isFirst) : _shareKeys,
                ),
                if (!keysShared)
                  TextButton(
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    child: Text('Skip for now', style: TextStyle(color: colors.textMuted)),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () => context.read<ThemeController>().cycle(),
                icon: Icon(
                  colors.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: colors.textSecondary,
                ),
              ),
            ),
            const Center(child: BrandLogo(size: 56)),
            const SizedBox(height: 12),
            Text(
              'Create your account',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textPrimary, fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'An end-to-end X25519 keypair is generated on this device. Your private key never leaves the phone.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: username,
              textCapitalization: TextCapitalization.none,
              decoration: const InputDecoration(
                hintText: 'Username',
                prefixIcon: Icon(Icons.person_outline, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Email address',
                prefixIcon: Icon(Icons.mail_outline, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: password,
              obscureText: !showPassword,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => showPassword = !showPassword),
                  icon: Icon(showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                ),
              ),
            ),
            if (password.text.isNotEmpty) PasswordStrengthMeter(password: password.text, colors: colors),
            if (auth.error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(auth.error!, style: TextStyle(color: colors.error)),
              ),
            ],
            const SizedBox(height: 20),
            QcPrimaryButton(
              label: auth.loading ? 'Creating account...' : 'Create account',
              loading: auth.loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: const Text('Already have an account? Log in'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
