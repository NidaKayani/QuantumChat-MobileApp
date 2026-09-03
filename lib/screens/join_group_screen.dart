import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/auth_controller.dart';
import '../state/chat_controller.dart';
import '../state/theme_controller.dart';
import 'thread_screen.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final codeCtrl = TextEditingController();
  Map<String, dynamic>? preview;
  bool loading = false;
  String? error;

  @override
  void dispose() {
    codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _preview() async {
    final code = codeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() {
      loading = true;
      error = null;
      preview = null;
    });
    try {
      final data = await context.read<AuthController>().api.previewInvite(code);
      if (!mounted) return;
      setState(() => preview = data);
    } catch (e) {
      setState(() => error = 'Invite not found or expired');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _join() async {
    final code = codeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final chat = context.read<ChatController>();
      final group = await chat.joinGroupViaInvite(code);
      if (!mounted) return;
      final matches = chat.conversations.where((c) => c.id == group.id).toList();
      final conv = matches.isNotEmpty
          ? matches.first
          : Conversation(
              key: chat.storage.conversationKeyForGroup(group.id),
              type: ConversationType.group,
              id: group.id,
              title: group.name,
              subtitle: group.description,
              group: group,
            );
      await chat.open(conv);
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ThreadScreen()),
      );
    } catch (e) {
      setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeController>().colors;
    return Scaffold(
      backgroundColor: colors.body,
      appBar: AppBar(
        title: const Text('Join group'),
        backgroundColor: colors.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter the invite code from a group admin',
              style: TextStyle(color: colors.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(
                hintText: 'Invite code',
                prefixIcon: Icon(Icons.link),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _preview(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: loading ? null : _preview,
                    child: const Text('Preview'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: loading ? null : _join,
                    child: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Join'),
                  ),
                ),
              ],
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, style: TextStyle(color: colors.error)),
            ],
            if (preview != null) ...[
              const SizedBox(height: 24),
              Card(
                color: colors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preview!['name'] as String? ?? 'Group',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if ((preview!['description'] as String? ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          preview!['description'] as String,
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        '${preview!['memberCount'] ?? 0} members',
                        style: TextStyle(color: colors.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
