import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_controller.dart';
import '../state/theme_controller.dart';
import '../theme/qc_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool loading = true;
  String? error;
  Map<String, dynamic> settings = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await context.read<AuthController>().api.getNotificationSettings();
      if (mounted) setState(() => settings = data);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _update(String key, dynamic value) async {
    final prev = settings[key];
    setState(() => settings[key] = value);
    try {
      final data = await context.read<AuthController>().api.updateNotificationSettings({key: value});
      if (mounted) setState(() => settings = data);
    } catch (e) {
      if (mounted) {
        setState(() => settings[key] = prev);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeController>().colors;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!, style: TextStyle(color: colors.error)))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    _SectionHeader(title: 'Messages', colors: colors),
                    _DropdownTile(
                      label: 'Message notifications',
                      value: settings['messageNotifications'] as String? ?? 'all',
                      options: const {
                        'all': 'All messages',
                        'all_except_reactions': 'All except reactions',
                        'mentions_only': 'Mentions only',
                        'off': 'Off',
                      },
                      colors: colors,
                      onChanged: (v) => _update('messageNotifications', v),
                    ),
                    _SwitchTile(
                      label: 'Group notifications',
                      value: settings['groupNotifications'] as bool? ?? true,
                      colors: colors,
                      onChanged: (v) => _update('groupNotifications', v),
                    ),
                    _SwitchTile(
                      label: 'Story notifications',
                      value: settings['statusNotifications'] as bool? ?? true,
                      colors: colors,
                      onChanged: (v) => _update('statusNotifications', v),
                    ),
                    const SizedBox(height: 16),
                    _SectionHeader(title: 'Sound & vibration', colors: colors),
                    _SwitchTile(
                      label: 'Sound',
                      value: settings['soundEnabled'] as bool? ?? true,
                      colors: colors,
                      onChanged: (v) => _update('soundEnabled', v),
                    ),
                    if (settings['soundEnabled'] == true) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text('Volume', style: TextStyle(color: colors.textPrimary)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Slider(
                                value: ((settings['soundVolume'] as num?)?.toDouble() ?? 80) / 100,
                                onChanged: (v) => _update('soundVolume', (v * 100).round()),
                                activeColor: colors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    _SwitchTile(
                      label: 'Vibration',
                      value: settings['vibration'] as bool? ?? true,
                      colors: colors,
                      onChanged: (v) => _update('vibration', v),
                    ),
                    const SizedBox(height: 16),
                    _SectionHeader(title: 'Other', colors: colors),
                    _SwitchTile(
                      label: 'Message preview',
                      value: settings['messagePreview'] as bool? ?? true,
                      colors: colors,
                      onChanged: (v) => _update('messagePreview', v),
                    ),
                    _SwitchTile(
                      label: 'Birthday reminders',
                      value: settings['birthdayReminders'] as bool? ?? true,
                      colors: colors,
                      onChanged: (v) => _update('birthdayReminders', v),
                    ),
                  ],
                ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.colors});
  final String title;
  final QcColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(title, style: TextStyle(color: colors.accentCyan, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({required this.label, required this.value, required this.colors, required this.onChanged});
  final String label;
  final bool value;
  final QcColors colors;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: TextStyle(color: colors.textPrimary)),
      value: value,
      activeTrackColor: colors.accent,
      onChanged: onChanged,
    );
  }
}

class _DropdownTile extends StatelessWidget {
  const _DropdownTile({
    required this.label,
    required this.value,
    required this.options,
    required this.colors,
    required this.onChanged,
  });
  final String label;
  final String value;
  final Map<String, String> options;
  final QcColors colors;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: colors.textPrimary))),
          DropdownButton<String>(
            value: options.containsKey(value) ? value : options.keys.first,
            dropdownColor: colors.elevated,
            underline: const SizedBox.shrink(),
            items: options.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: TextStyle(color: colors.textSecondary))))
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
