import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/chat_controller.dart';
import '../state/theme_controller.dart';
import '../theme/qc_theme.dart';
import '../widgets/attachment_bubble.dart';
import '../widgets/common.dart';
import '../widgets/gif_picker_sheet.dart';
import '../widgets/message_actions_sheet.dart';
import '../widgets/theme_scene.dart';
import 'group_info_screen.dart';

class ThreadScreen extends StatefulWidget {
  const ThreadScreen({super.key});

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<ThreadScreen> {
  final composer = TextEditingController();
  final scroll = ScrollController();
  final searchCtrl = TextEditingController();
  bool searching = false;
  String searchQuery = '';
  Timer? _liveRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<ChatController>().refreshOpenThread());
    });
    _liveRefresh = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      unawaited(context.read<ChatController>().refreshOpenThread());
    });
  }

  @override
  void dispose() {
    _liveRefresh?.cancel();
    composer.dispose();
    scroll.dispose();
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = composer.text;
    composer.clear();
    await context.read<ChatController>().sendText(text);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (scroll.hasClients) {
      scroll.animateTo(
        scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  List<ChatMessage> _visible(ChatController chat) {
    if (searchQuery.trim().isEmpty) return chat.messages;
    final q = searchQuery.trim().toLowerCase();
    return chat.messages.where((m) => (m.text ?? '').toLowerCase().contains(q)).toList();
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    await context.read<ChatController>().sendAttachmentBytes(
          bytes: bytes,
          filename: file.name,
          mimetype: file.mimeType ?? 'image/jpeg',
        );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty || !mounted) return;
    final f = result.files.first;
    final bytes = f.bytes;
    if (bytes == null) return;
    await context.read<ChatController>().sendAttachmentBytes(
          bytes: bytes,
          filename: f.name,
          mimetype: f.extension != null ? 'application/${f.extension}' : 'application/octet-stream',
        );
  }

  Future<void> _attachSheet() async {
    final colors = context.read<ThemeController>().colors;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('File'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.gif_box_outlined),
              title: const Text('GIF'),
              onTap: () {
                Navigator.pop(ctx);
                showGifPickerSheet(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chatOptions() async {
    final chat = context.read<ChatController>();
    final colors = context.read<ThemeController>().colors;
    final conv = chat.selected;
    if (conv == null) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (conv.type == ConversationType.group)
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Group info'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => GroupInfoScreen(groupId: conv.id)),
                  );
                },
              ),
            ListTile(
              leading: Icon(conv.muted ? Icons.notifications_active_outlined : Icons.notifications_off_outlined),
              title: Text(conv.muted ? 'Unmute' : 'Mute'),
              onTap: () async {
                Navigator.pop(ctx);
                if (conv.muted) {
                  await chat.unmuteSelected();
                } else {
                  await chat.muteSelected();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep_outlined),
              title: const Text('Clear chat'),
              onTap: () async {
                Navigator.pop(ctx);
                await chat.clearSelectedChat();
              },
            ),
            if (conv.type == ConversationType.dm && !conv.isSelfChat)
              ListTile(
                leading: Icon(Icons.block, color: colors.error),
                title: Text('Block', style: TextStyle(color: colors.error)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await chat.blockPeer(conv.id);
                  if (mounted) Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();
    final theme = context.watch<ThemeController>();
    final colors = theme.colors;
    final scenic = theme.isFunTheme;
    final conv = chat.selected;
    if (conv == null) {
      return const Scaffold(body: Center(child: Text('No conversation')));
    }
    final typingName = chat.typingFrom == null ? null : chat.displayName(chat.typingFrom!);
    final visible = _visible(chat);

    // Sync composer when editing
    if (chat.editing != null && composer.text != (chat.editing!.text ?? '')) {
      // don't fight user typing mid-edit after first set — only when opening edit
    }

    return Scaffold(
      backgroundColor: scenic ? Colors.transparent : colors.chat,
      extendBodyBehindAppBar: scenic,
      appBar: AppBar(
        backgroundColor: scenic ? colors.surface.withValues(alpha: 0.52) : colors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: searching
            ? TextField(
                controller: searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search messages…',
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (v) => setState(() => searchQuery = v),
              )
            : Row(
                children: [
                  UserAvatar(
                    name: conv.title,
                    userId: conv.id,
                    hasAvatar: conv.peer?.hasAvatar == true || conv.group?.hasPhoto == true,
                    online: conv.online,
                    size: 36,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(conv.title, overflow: TextOverflow.ellipsis),
                        Text(
                          typingName != null
                              ? '$typingName is typing…'
                              : conv.type == ConversationType.group
                                  ? (conv.subtitle ?? 'Group')
                                  : (conv.online ? 'online' : formatLastSeen(conv.peer?.lastLoginAt)),
                          style: TextStyle(
                            color: typingName != null ? colors.accentCyan : colors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            tooltip: searching ? 'Close search' : 'Search',
            onPressed: () {
              setState(() {
                searching = !searching;
                if (!searching) {
                  searchQuery = '';
                  searchCtrl.clear();
                }
              });
            },
            icon: Icon(searching ? Icons.close : Icons.search),
          ),
          IconButton(
            tooltip: 'Options',
            onPressed: _chatOptions,
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: ThemeScene(
        themeId: theme.id,
        child: Column(
          children: [
            if (scenic) SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
            if (chat.threadError != null)
              Material(
                color: colors.error.withValues(alpha: 0.12),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(chat.threadError!, style: TextStyle(color: colors.error)),
                ),
              ),
            Expanded(
              child: chat.loadingThread
                  ? const Center(child: CircularProgressIndicator())
                  : visible.isEmpty
                      ? Center(
                          child: Text(
                            searchQuery.isNotEmpty
                                ? 'No matches'
                                : 'No messages yet. Say hello — it is sealed before it leaves this phone.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.textMuted),
                          ),
                        )
                      : ListView.builder(
                          controller: scroll,
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                          itemCount: visible.length,
                          itemBuilder: (context, i) {
                            final m = visible[i];
                            final mine = m.isMine(chat.me.id);
                            final showName = conv.type == ConversationType.group && !mine;
                            return _MessageBubble(
                              message: m,
                              mine: mine,
                              showName: showName,
                              senderName: showName ? chat.displayName(m.from) : null,
                              colors: colors,
                              scenic: scenic,
                              highlight: searchQuery.isNotEmpty,
                              onOpenActions: () => _messageActions(m),
                            );
                          },
                        ),
            ),
            if (chat.replyTo != null || chat.editing != null)
              Container(
                width: double.infinity,
                color: colors.elevated.withValues(alpha: 0.9),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(chat.editing != null ? Icons.edit : Icons.reply, size: 18, color: colors.accentCyan),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        chat.editing != null
                            ? 'Editing: ${chat.editing!.text ?? ''}'
                            : 'Replying to: ${chat.replyTo!.text ?? 'message'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.textSecondary, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        chat.clearComposerContext();
                        if (chat.editing == null) composer.clear();
                      },
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
              ),
            SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: scenic ? colors.surface.withValues(alpha: 0.62) : colors.surface,
                  border: Border(top: BorderSide(color: colors.border.withValues(alpha: scenic ? 0.45 : 1))),
                ),
                padding: const EdgeInsets.fromLTRB(6, 8, 10, 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: chat.sending ? null : _attachSheet,
                      icon: Icon(Icons.add_circle_outline, color: colors.accent),
                    ),
                    Expanded(
                      child: TextField(
                        controller: composer,
                        minLines: 1,
                        maxLines: 5,
                        onChanged: chat.onComposerChanged,
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration(
                          hintText: chat.editing != null ? 'Edit message…' : 'Encrypted message…',
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    CircleAvatar(
                      backgroundColor: colors.accent,
                      child: IconButton(
                        onPressed: chat.sending ? null : _send,
                        icon: chat.sending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(Icons.send, color: colors.bubbleMineFg, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _messageActions(ChatMessage message) async {
    final chat = context.read<ChatController>();
    final colors = context.read<ThemeController>().colors;
    final mine = message.isMine(chat.me.id);
    final action = await showMessageActionsSheet(
      context: context,
      message: message,
      colors: colors,
      mine: mine,
    );
    if (action == null || !mounted) return;

    if (action.startsWith('react:')) {
      final ok = await chat.react(message, action.substring(6));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? 'Reaction added' : (chat.threadError ?? 'Reaction failed'))),
        );
      }
    } else if (action == 'reply') {
      chat.setReplyTo(message);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Replying — type your message below')),
        );
      }
    } else if (action == 'copy' && message.text != null) {
      await Clipboard.setData(ClipboardData(text: message.text!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
      }
    } else if (action == 'edit') {
      chat.setEditing(message);
      composer.text = message.text ?? '';
      composer.selection = TextSelection.collapsed(offset: composer.text.length);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Editing — change text and send')),
        );
      }
    } else if (action == 'delete_everyone') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete for everyone?'),
          content: const Text('This removes the message for all participants.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
          ],
        ),
      );
      if (ok == true && mounted) {
        await chat.deleteMessage(message, forEveryone: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message deleted')));
        }
      }
    } else if (action == 'delete_me') {
      await chat.deleteMessage(message, forEveryone: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from this device')));
      }
    }
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.mine,
    required this.showName,
    required this.senderName,
    required this.colors,
    required this.scenic,
    required this.onOpenActions,
    this.highlight = false,
  });

  final ChatMessage message;
  final bool mine;
  final bool showName;
  final String? senderName;
  final QcColors colors;
  final bool scenic;
  final VoidCallback onOpenActions;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpenActions,
          onLongPress: onOpenActions,
          borderRadius: BorderRadius.circular(18),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 6),
              decoration: glassBubbleDecoration(mine: mine, colors: colors, scenic: scenic).copyWith(
                border: highlight
                    ? Border.all(color: colors.accentCyan, width: 1.5)
                    : glassBubbleDecoration(mine: mine, colors: colors, scenic: scenic).border,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (showName && senderName != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  senderName!,
                                  style: TextStyle(
                                    color: colors.accentCyan,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            if (message.replyToText != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colors.overlay.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border(left: BorderSide(color: colors.accentCyan, width: 3)),
                                  ),
                                  child: Text(
                                    message.replyToText!,
                                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                                  ),
                                ),
                              ),
                            if (message.attachment != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: AttachmentBubble(message: message, colors: colors),
                              ),
                            if (message.text != null && message.attachment == null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  message.text!,
                                  style: TextStyle(
                                    color: mine ? colors.bubbleMineFg : colors.bubbleTheirsFg,
                                    height: 1.35,
                                  ),
                                ),
                              )
                            else if (message.text == null && message.attachment == null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Unable to decrypt',
                                  style: TextStyle(
                                    color: colors.textMuted,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        tooltip: 'Message options',
                        onPressed: onOpenActions,
                        icon: Icon(Icons.more_vert, size: 18, color: colors.textMuted.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.editedAt != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text('edited', style: TextStyle(color: colors.textMuted, fontSize: 10)),
                        ),
                      if (message.reactions.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.overlay.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              message.reactions.map((r) => r.emoji).whereType<String>().join(' '),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      Text(
                        formatMessageTime(message.createdAt),
                        style: TextStyle(
                          color: mine ? colors.bubbleMineFg.withValues(alpha: 0.78) : colors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      if (mine) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.readAt != null
                              ? Icons.done_all
                              : message.deliveredAt != null
                                  ? Icons.done_all
                                  : Icons.done,
                          size: 14,
                          color: message.readAt != null
                              ? colors.accentCyan
                              : colors.bubbleMineFg.withValues(alpha: 0.78),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
