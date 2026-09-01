import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/auth_controller.dart';
import '../state/chat_controller.dart';
import '../state/theme_controller.dart';
import '../widgets/common.dart';

class GroupInfoScreen extends StatefulWidget {
  const GroupInfoScreen({super.key, required this.groupId});

  final String groupId;

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  QcGroup? group;
  bool loading = true;
  String? error;

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
      final g = await context.read<AuthController>().api.getGroup(widget.groupId);
      if (!mounted) return;
      setState(() => group = g);
      await context.read<ChatController>().refreshGroup(widget.groupId);
    } catch (e) {
      setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  bool _isAdmin(QcUser me) {
    final g = group;
    if (g == null) return false;
    return g.admins.map((e) => e.toString()).contains(me.id);
  }

  Future<void> _addMember() async {
    final chat = context.read<ChatController>();
    final colors = context.read<ThemeController>().colors;
    final candidates = chat.users.where((u) => !(group?.members.any((m) => m.id == u.id) ?? false)).toList();
    final picked = await showModalBottomSheet<QcUser>(
      context: context,
      backgroundColor: colors.surface,
      builder: (ctx) => SafeArea(
        child: ListView(
          children: [
            const ListTile(title: Text('Add member')),
            ...candidates.map(
              (u) => ListTile(
                leading: UserAvatar(name: u.title, userId: u.id, hasAvatar: u.hasAvatar),
                title: Text(u.title),
                subtitle: Text('@${u.username}'),
                onTap: () => Navigator.pop(ctx, u),
              ),
            ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    try {
      await context.read<AuthController>().api.addGroupMembers(widget.groupId, [picked.id]);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _removeMember(QcUser member) async {
    final me = context.read<AuthController>().user!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(member.id == me.id ? 'Leave group?' : 'Remove member?'),
        content: Text(member.id == me.id ? 'You will leave this group.' : 'Remove ${member.title}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<AuthController>().api.removeGroupMember(widget.groupId, member.id);
      if (member.id == me.id && mounted) {
        context.read<ChatController>().closeThread();
        Navigator.of(context).popUntil((r) => r.isFirst);
        await context.read<ChatController>().refreshInbox();
        return;
      }
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeController>().colors;
    final me = context.watch<AuthController>().user!;
    final g = group;

    return Scaffold(
      appBar: AppBar(title: Text(g?.name ?? 'Group')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!, style: TextStyle(color: colors.error)))
              : g == null
                  ? const Center(child: Text('Group not found'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Center(
                          child: UserAvatar(
                            name: g.name,
                            userId: g.id,
                            hasAvatar: g.hasPhoto,
                            isGroup: true,
                            size: 72,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(g.name, style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                        ),
                        if (g.description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Center(child: Text(g.description, style: TextStyle(color: colors.textMuted))),
                        ],
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            '${g.members.length} members',
                            style: TextStyle(color: colors.textSecondary),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_isAdmin(me))
                          QcPrimaryButton(label: 'Add member', onPressed: _addMember),
                        const SizedBox(height: 16),
                        Text('Members', style: TextStyle(color: colors.accentCyan, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        ...g.members.map((m) {
                          final admin = g.admins.contains(m.id);
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: UserAvatar(name: m.title, userId: m.id, hasAvatar: m.hasAvatar),
                            title: Text(m.title, style: TextStyle(color: colors.textPrimary)),
                            subtitle: Text(
                              admin ? '@${m.username} · admin' : '@${m.username}',
                              style: TextStyle(color: colors.textMuted),
                            ),
                            trailing: (m.id == me.id || _isAdmin(me))
                                ? IconButton(
                                    tooltip: m.id == me.id ? 'Leave' : 'Remove',
                                    onPressed: () => _removeMember(m),
                                    icon: Icon(
                                      m.id == me.id ? Icons.logout : Icons.person_remove_outlined,
                                      color: colors.error,
                                    ),
                                  )
                                : null,
                          );
                        }),
                        const SizedBox(height: 24),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: colors.error, side: BorderSide(color: colors.error)),
                          onPressed: () => _removeMember(me),
                          child: const Text('Leave group'),
                        ),
                      ],
                    ),
    );
  }
}
