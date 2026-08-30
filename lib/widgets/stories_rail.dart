import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/auth_controller.dart';
import '../state/chat_controller.dart';
import '../state/theme_controller.dart';
import 'common.dart';

class StoriesRail extends StatelessWidget {
  const StoriesRail({super.key});

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();
    final colors = context.watch<ThemeController>().colors;
    final me = context.watch<AuthController>().user;
    if (me == null) return const SizedBox.shrink();

    // Group by user, keep latest
    final byUser = <String, StoryItem>{};
    for (final s in chat.stories) {
      final prev = byUser[s.userId];
      if (prev == null || (s.createdAt != null && (prev.createdAt == null || s.createdAt!.isAfter(prev.createdAt!)))) {
        byUser[s.userId] = s;
      }
    }
    final items = byUser.values.toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        children: [
          _AddStoryChip(
            colors: colors,
            onTap: () => _createStory(context),
          ),
          ...items.map(
            (s) => _StoryChip(
              story: s,
              colors: colors,
              onTap: () => _openStory(context, s),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createStory(BuildContext context) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null || !context.mounted) return;
    final bytes = await file.readAsBytes();
    final mime = file.mimeType ?? 'image/jpeg';
    if (!context.mounted) return;
    try {
      await context.read<ChatController>().postStory(
            bytes,
            filename: file.name,
            mimetype: mime,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Story posted')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _openStory(BuildContext context, StoryItem story) async {
    final colors = context.read<ThemeController>().colors;
    final api = context.read<AuthController>().api;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) {
        return FutureBuilder(
          future: () async {
            await api.markStoryViewed(story.id);
            return api.getStoryMedia(story.id);
          }(),
          builder: (context, snap) {
            Widget body;
            if (snap.connectionState != ConnectionState.done) {
              body = const CircularProgressIndicator();
            } else if (snap.data == null) {
              body = Text('Could not load story', style: TextStyle(color: colors.textPrimary));
            } else {
              body = InteractiveViewer(
                child: Image.memory(snap.data!, fit: BoxFit.contain),
              );
            }
            return Dialog(
              backgroundColor: Colors.black,
              insetPadding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: UserAvatar(name: story.username, userId: story.userId, hasAvatar: story.hasAvatar, size: 36),
                    title: Text(story.username, style: const TextStyle(color: Colors.white)),
                    trailing: IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.7,
                      maxWidth: MediaQuery.of(context).size.width,
                    ),
                    child: Center(child: body),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AddStoryChip extends StatelessWidget {
  const _AddStoryChip({required this.colors, required this.onTap});
  final dynamic colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.accent, width: 2),
                color: colors.elevated,
              ),
              child: Icon(Icons.add, color: colors.accent),
            ),
            const SizedBox(height: 6),
            Text('Your story', style: TextStyle(color: colors.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _StoryChip extends StatelessWidget {
  const _StoryChip({required this.story, required this.colors, required this.onTap});
  final StoryItem story;
  final dynamic colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [colors.accent, colors.accentCyan]),
              ),
              child: UserAvatar(name: story.username, userId: story.userId, hasAvatar: story.hasAvatar, size: 54),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 64,
              child: Text(
                story.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textMuted, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
