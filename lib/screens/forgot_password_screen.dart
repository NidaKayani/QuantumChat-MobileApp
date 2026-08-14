import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/auth_controller.dart';
import '../state/theme_controller.dart';
import '../widgets/common.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final email = TextEditingController();
  String? done;
  String? error;
  bool busy = false;

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      busy = true;
      error = null;
      done = null;
    });
    try {
      final data = await context.read<AuthController>().api.forgotPassword(email.text.trim());
      setState(() => done = data['message'] as String? ?? 'If that email exists, a reset link was sent.');
    } on ApiException catch (e) {
      setState(() => error = e.message);
    } finally {
      setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeController>().colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Resets login access only. Encrypted message keys stay on your devices — keep your keys.txt backup.',
            style: TextStyle(color: colors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 20),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(error!, style: TextStyle(color: colors.error)),
            ),
          if (done != null)
            Text(done!, style: TextStyle(color: colors.success))
          else ...[
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'Email'),
            ),
            const SizedBox(height: 16),
            QcPrimaryButton(label: busy ? 'Sending…' : 'Send reset link', loading: busy, onPressed: _submit),
          ],
        ],
      ),
    );
  }
}

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.token});
  final String token;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final password = TextEditingController();
  bool busy = false;
  String? error;
  String? ok;

  @override
  void dispose() {
    password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await context.read<AuthController>().api.resetPassword(
            token: widget.token,
            newPassword: password.text,
          );
      setState(() => ok = 'Password reset. You can log in now.');
    } on ApiException catch (e) {
      setState(() => error = e.message);
    } finally {
      setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeController>().colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Choose a new login password. This does not change your encryption keys.',
            style: TextStyle(color: colors.textSecondary),
          ),
          const SizedBox(height: 16),
          if (widget.token.isEmpty)
            Text('Missing reset token. Use the link from your email.', style: TextStyle(color: colors.error)),
          if (error != null) Text(error!, style: TextStyle(color: colors.error)),
          if (ok != null) Text(ok!, style: TextStyle(color: colors.success)),
          TextField(
            controller: password,
            obscureText: true,
            enabled: widget.token.isNotEmpty,
            decoration: const InputDecoration(hintText: 'New password'),
          ),
          const SizedBox(height: 16),
          QcPrimaryButton(
            label: busy ? 'Saving…' : 'Reset password',
            loading: busy,
            onPressed: widget.token.isEmpty || password.text.length < 8 ? null : _submit,
          ),
        ],
      ),
    );
  }
}
