import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/auth_controller.dart';
import '../state/chat_controller.dart';
import '../state/theme_controller.dart';
import '../widgets/common.dart';
import 'new_chat_screen.dart';
import 'settings_screen.dart';
import 'thread_screen.dart';

class ChatHomeScreen extends StatefulWidget {
  const ChatHomeScreen({super.key});

  @override
  State<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen> {
  final search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatController>().start();
    });
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();
    final auth = context.watch<AuthController>();
    final colors = context.watch<ThemeController>().colors;
    const filters = [
      ('all', 'All'),
      ('unread', 'Unread'),
      ('groups', 'Groups'),
      ('friends', 'Friends'),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('QuantumChat'),
            Text(
              auth.user?.title ?? '',
              style: TextStyle(color: colors.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'New chat',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewChatScreen())),
            icon: const Icon(Icons.person_add_alt_1_outlined),
          ),
          IconButton(
            tooltip: 'New group',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroupScreen())),
            icon: const Icon(Icons.group_add_outlined),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          if (auth.user?.emailVerified == false)
            Material(
              color: colors.accentMuted,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(child: Text('Verify your email', style: TextStyle(color: colors.textPrimary))),
                    TextButton(
                      onPressed: () async {
                        try {
                          await auth.api.resendVerification();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Verification email sent')),
                            );
                          }
                        } catch (_) {}
                      },
                      child: const Text('Resend'),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: search,
              onChanged: (v) => chat.searchPeople(v),
              decoration: InputDecoration(
                hintText: 'Search conversations',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: search.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          search.clear();
                          chat.searchPeople('');
                        },
                        icon: const Icon(Icons.close, size: 18),
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: filters.map((f) {
                final selected = chat.filter == f.$1;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(f.$2),
                    selected: selected,
                    onSelected: (_) => chat.setFilter(f.$1),
                    selectedColor: colors.accent,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: colors.elevated,
                    side: BorderSide(color: selected ? colors.accent : colors.border),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: chat.loadingInbox && chat.conversations.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: chat.refreshInbox,
                    child: chat.conversations.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 80),
                              Icon(Icons.chat_bubble_outline, size: 48, color: colors.textMuted),
                              const SizedBox(height: 12),
                              Text(
                                'No conversations yet',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: colors.textSecondary),
                              ),
                            ],
                          )
                        : ListView.separated(
                            itemCount: chat.conversations.length,
                            separatorBuilder: (_, __) => Divider(height: 1, color: colors.border.withValues(alpha: 0.6)),
                            itemBuilder: (context, i) {
                              final c = chat.conversations[i];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                leading: UserAvatar(
                                  name: c.title,
                                  userId: c.id,
                                  hasAvatar: c.peer?.hasAvatar == true || c.group?.hasPhoto == true,
                                  online: c.online,
                                  size: 48,
                                ),
                                title: Text(
                                  c.title,
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontWeight: c.unread ? FontWeight.w800 : FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  c.subtitle ??
                                      (c.online
                                          ? 'online'
                                          : formatLastSeen(c.peer?.lastLoginAt, online: c.online)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: c.unread ? colors.accentCyan : colors.textMuted),
                                ),
                                trailing: c.unread
                                    ? Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(color: colors.accent, shape: BoxShape.circle),
                                      )
                                    : null,
                                onTap: () async {
                                  await chat.open(c);
                                  if (context.mounted) {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const ThreadScreen()),
                                    );
                                    chat.closeThread();
                                  }
                                },
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
