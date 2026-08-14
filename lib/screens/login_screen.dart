import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_controller.dart';
import '../state/theme_controller.dart';
import '../widgets/brand_logo.dart';
import '../widgets/common.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final totp = TextEditingController();
  bool rememberMe = true;
  bool showPassword = false;

  @override
  void initState() {
    super.initState();
    final remembered = context.read<AuthController>().storage.getRememberedEmail();
    if (remembered != null) email.text = remembered;
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    totp.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthController>();
    if (auth.pending2faTempToken != null) {
      if (!RegExp(r'^\d{6}$').hasMatch(totp.text.trim())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter the 6-digit code from your authenticator app.')),
        );
        return;
      }
      await auth.verify2fa(totp.text.trim());
      return;
    }
    if (email.text.trim().isEmpty || password.text.isEmpty) return;
    final ok = await auth.login(
      email: email.text.trim(),
      password: password.text,
      rememberMe: rememberMe,
    );
    if (ok && rememberMe) {
      await auth.storage.setRememberedEmail(email.text.trim());
    } else if (ok) {
      await auth.storage.setRememberedEmail(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final colors = context.watch<ThemeController>().colors;
    final twoFa = auth.pending2faTempToken != null;

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
            Center(
              child: Text('QuantumChat', style: TextStyle(color: colors.accentCyan, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 8),
            Text(
              twoFa ? 'Two-factor authentication' : 'Welcome back',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textPrimary, fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              twoFa
                  ? 'Enter the 6-digit code from your authenticator app.'
                  : 'Sign in to decrypt your conversations.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary),
            ),
            const SizedBox(height: 28),
            if (!twoFa) ...[
              Text('Email address', style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  hintText: 'name@example.com',
                  prefixIcon: Icon(Icons.mail_outline, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text('Password', style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                    ),
                    child: const Text('Forgot password?'),
                  ),
                ],
              ),
              TextField(
                controller: password,
                obscureText: !showPassword,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  hintText: 'Your password',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => showPassword = !showPassword),
                    icon: Icon(showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: rememberMe,
                onChanged: (v) => setState(() => rememberMe = v ?? true),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text('Keep me signed in on this device', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
              ),
            ] else ...[
              TextField(
                controller: totp,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(letterSpacing: 8, fontSize: 22, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(hintText: '000000', counterText: ''),
              ),
              TextButton(
                onPressed: () {
                  totp.clear();
                  auth.cancel2fa();
                },
                child: const Text('← Back to password'),
              ),
            ],
            if (auth.error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(auth.error!, style: TextStyle(color: colors.error)),
              ),
            ],
            const SizedBox(height: 16),
            QcPrimaryButton(
              label: auth.loading ? 'Please wait…' : twoFa ? 'Verify & continue' : 'Log in',
              loading: auth.loading,
              onPressed: _submit,
            ),
            if (!twoFa) ...[
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: const Text('New here? Create an account'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
