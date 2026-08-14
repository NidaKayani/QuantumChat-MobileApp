import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../crypto/qc_crypto.dart';
import '../models/models.dart';
import '../state/auth_controller.dart';
import '../state/theme_controller.dart';
import '../widgets/common.dart';

class UnlockKeysScreen extends StatefulWidget {
  const UnlockKeysScreen({super.key});

  @override
  State<UnlockKeysScreen> createState() => _UnlockKeysScreenState();
}

class _UnlockKeysScreenState extends State<UnlockKeysScreen> {
  String? importError;
  bool busy = false;

  Future<void> _import() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final text = file.bytes != null
        ? String.fromCharCodes(file.bytes!)
        : await File(file.path!).readAsString();
    setState(() {
      busy = true;
      importError = null;
    });
    try {
      final keys = parseKeyFile(text);
      await context.read<AuthController>().importKeys(keys);
    } on ApiException catch (e) {
      setState(() => importError = e.message);
    } catch (e) {
      setState(() => importError = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _generate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colors = ctx.watch<ThemeController>().colors;
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text('Generate new encryption keys?', style: TextStyle(color: colors.textPrimary)),
          content: Text(
            'This creates a new 5-key pool on this device and publishes it to the server. Messages encrypted with previous keys will stay unreadable.',
            style: TextStyle(color: colors.textSecondary),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Generate new keys', style: TextStyle(color: colors.error)),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    try {
      final auth = context.read<AuthController>();
      final keySet = await auth.regenerateKeys();
      final user = auth.user!;
      final content = formatKeyFile(
        username: user.username,
        email: user.email ?? '',
        secretKeys: keySet.map((k) => k.secretKey).toList(),
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/keys.txt');
      await file.writeAsString(content);
      await Share.shareXFiles([XFile(file.path)], text: 'QuantumChat private keys');
    } on ApiException catch (e) {
      setState(() => importError = e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final colors = context.watch<ThemeController>().colors;
    final name = auth.user?.username ?? auth.user?.email ?? 'this account';

    return Scaffold(
      appBar: AppBar(
        title: const Text('QuantumChat'),
        actions: [
          IconButton(
            onPressed: () => auth.logout(),
            icon: Icon(Icons.logout, color: colors.textSecondary),
            tooltip: 'Log out',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.accentMuted,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(Icons.lock_outline, color: colors.accent, size: 32),
                ),
                const SizedBox(height: 20),
                Text(
                  'Unlock your encryption keys',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  'This phone does not have keys for $name yet. Import your keys.txt once — they stay on this device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textSecondary, height: 1.45),
                ),
                if (importError != null) ...[
                  const SizedBox(height: 12),
                  Text(importError!, style: TextStyle(color: colors.error), textAlign: TextAlign.center),
                ],
                const SizedBox(height: 24),
                QcPrimaryButton(
                  label: 'Import keys.txt for this account',
                  loading: busy,
                  onPressed: _import,
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: busy ? null : _generate,
                  child: const Text('Lost your keys? Generate new set'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Generating new keys keeps you chatting, but messages encrypted with your old keys stay unreadable.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textMuted, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
