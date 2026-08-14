import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/auth_controller.dart';
import '../state/chat_controller.dart';
import '../state/theme_controller.dart';
import '../theme/qc_theme.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final displayName = TextEditingController(text: context.read<AuthController>().user?.displayName ?? '');
  late final bio = TextEditingController(text: context.read<AuthController>().user?.bio ?? '');
  late final apiBase = TextEditingController(text: context.read<AuthController>().apiBase);
  String? status;

  @override
  void dispose() {
    displayName.dispose();
    bio.dispose();
    apiBase.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final auth = context.read<AuthController>();
    try {
      final updated = await auth.api.updateProfile({
        'displayName': displayName.text.trim(),
        'bio': bio.text.trim(),
      });
      auth.updateUser(updated);
      setState(() => status = 'Profile saved');
    } on ApiException catch (e) {
      setState(() => status = e.message);
    }
  }

  Future<void> _savePrivacy(String field, String value) async {
    final auth = context.read<AuthController>();
    try {
      final updated = await auth.api.updatePrivacy({field: value});
      auth.updateUser(updated);
    } on ApiException catch (e) {
      setState(() => status = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final theme = context.watch<ThemeController>();
    final colors = theme.colors;
    final user = auth.user!;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Center(child: UserAvatar(name: user.title, userId: user.id, hasAvatar: user.hasAvatar, size: 72)),
          const SizedBox(height: 8),
          Center(child: Text('@${user.username}', style: TextStyle(color: colors.textMuted))),
          if (status != null) ...[
            const SizedBox(height: 8),
            Text(status!, textAlign: TextAlign.center, style: TextStyle(color: colors.accentCyan)),
          ],
          const SizedBox(height: 20),
          _Section(title: 'Profile', colors: colors),
          TextField(controller: displayName, decoration: const InputDecoration(hintText: 'Display name')),
          const SizedBox(height: 10),
          TextField(controller: bio, maxLines: 3, decoration: const InputDecoration(hintText: 'Bio')),
          const SizedBox(height: 10),
          QcPrimaryButton(label: 'Save profile', onPressed: _saveProfile),
          const SizedBox(height: 24),
          _Section(title: 'Appearance', colors: colors),
          Wrap(
            spacing: 8,
            children: QcThemeId.values.map((id) {
              final selected = theme.id == id;
              return ChoiceChip(
                label: Text(id.name[0].toUpperCase() + id.name.substring(1)),
                selected: selected,
                onSelected: (_) => theme.setTheme(id),
                selectedColor: colors.accent,
                labelStyle: TextStyle(color: selected ? Colors.white : colors.textSecondary),
                backgroundColor: colors.elevated,
                side: BorderSide(color: selected ? colors.accent : colors.border),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          _Section(title: 'Privacy', colors: colors),
          _PrivacyTile(
            label: 'Last seen',
            value: user.privacy.lastSeen,
            onChanged: (v) => _savePrivacy('lastSeen', v),
            colors: colors,
          ),
          _PrivacyTile(
            label: 'Online status',
            value: user.privacy.online,
            onChanged: (v) => _savePrivacy('online', v),
            colors: colors,
          ),
          _PrivacyTile(
            label: 'Read receipts',
            value: user.privacy.readReceipts,
            onChanged: (v) => _savePrivacy('readReceipts', v),
            colors: colors,
          ),
          _PrivacyTile(
            label: 'Who can message you',
            value: user.privacy.whoCanMessage,
            onChanged: (v) => _savePrivacy('whoCanMessage', v),
            colors: colors,
          ),
          const SizedBox(height: 24),
          _Section(title: 'Server', colors: colors),
          Text(
            'Point this app at the QuantumChat backend. Android emulator: http://10.0.2.2:5000',
            style: TextStyle(color: colors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextField(controller: apiBase, decoration: const InputDecoration(hintText: 'http://10.0.2.2:5000')),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () async {
              await auth.setApiBase(apiBase.text.trim());
              setState(() => status = 'API URL saved. Log out and back in if you were already connected.');
            },
            child: const Text('Save API URL'),
          ),
          const SizedBox(height: 24),
          _Section(title: 'Security', colors: colors),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Encryption keys', style: TextStyle(color: colors.textPrimary)),
            subtitle: Text(
              'Private keys stay on this device. Logout does not delete them.',
              style: TextStyle(color: colors.textMuted),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: colors.error, side: BorderSide(color: colors.error)),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: colors.surface,
                  title: Text('Log out?', style: TextStyle(color: colors.textPrimary)),
                  content: Text(
                    'You will need to sign in again. Encryption keys stay on this phone.',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log out')),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                context.read<ChatController>().stop();
                await auth.logout();
                if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
              }
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.colors});
  final String title;
  final QcColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: TextStyle(color: colors.accentCyan, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
    );
  }
}

class _PrivacyTile extends StatelessWidget {
  const _PrivacyTile({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.colors,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final QcColors colors;

  @override
  Widget build(BuildContext context) {
    const options = ['everyone', 'friends', 'nobody'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: colors.textPrimary))),
          DropdownButton<String>(
            value: options.contains(value) ? value : 'everyone',
            dropdownColor: colors.elevated,
            underline: const SizedBox.shrink(),
            items: options
                .map((o) => DropdownMenuItem(value: o, child: Text(o, style: TextStyle(color: colors.textSecondary))))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}
