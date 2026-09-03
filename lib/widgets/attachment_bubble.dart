import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/chat_controller.dart';
import '../theme/qc_theme.dart';
import 'image_lightbox.dart';

class AttachmentBubble extends StatefulWidget {
  const AttachmentBubble({
    super.key,
    required this.message,
    required this.colors,
  });

  final ChatMessage message;
  final QcColors colors;

  @override
  State<AttachmentBubble> createState() => _AttachmentBubbleState();
}

class _AttachmentBubbleState extends State<AttachmentBubble> {
  Uint8List? _bytes;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.message.attachment == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bytes = await context.read<ChatController>().decryptAttachment(widget.message);
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _loading = false;
        if (bytes == null) _error = 'Could not decrypt';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final att = widget.message.attachment;
    if (att == null) return const SizedBox.shrink();

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_error != null) {
      return Text(_error!, style: TextStyle(color: widget.colors.error, fontSize: 12));
    }
    if (_bytes != null && att.isImage) {
      return GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ImageLightbox(
                bytes: _bytes!,
                filename: att.filename,
                timestamp: widget.message.createdAt,
                colors: widget.colors,
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            _bytes!,
            width: 220,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _FileChip(att: att, colors: widget.colors),
          ),
        ),
      );
    }
    return _FileChip(att: att, colors: widget.colors);
  }
}

class _FileChip extends StatelessWidget {
  const _FileChip({required this.att, required this.colors});
  final AttachmentMeta att;
  final QcColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.insert_drive_file_outlined, color: colors.accentCyan, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            att.filename,
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
