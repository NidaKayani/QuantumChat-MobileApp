import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../theme/qc_theme.dart';
import '../widgets/common.dart';

/// Full-screen image viewer with pinch-to-zoom and swipe-to-dismiss.
class ImageLightbox extends StatefulWidget {
  const ImageLightbox({
    super.key,
    required this.bytes,
    required this.filename,
    this.timestamp,
    required this.colors,
  });

  final Uint8List bytes;
  final String filename;
  final DateTime? timestamp;
  final QcColors colors;

  @override
  State<ImageLightbox> createState() => _ImageLightboxState();
}

class _ImageLightboxState extends State<ImageLightbox> {
  double _dragOffset = 0;
  double _opacity = 1.0;

  void _onVerticalDragUpdate(DragUpdateDetails d) {
    setState(() {
      _dragOffset += d.delta.dy;
      _opacity = (1.0 - (_dragOffset.abs() / 300)).clamp(0.3, 1.0);
    });
  }

  void _onVerticalDragEnd(DragEndDetails d) {
    if (_dragOffset.abs() > 100 || d.velocity.pixelsPerSecond.dy.abs() > 600) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _dragOffset = 0;
        _opacity = 1.0;
      });
    }
  }

  Future<void> _share() async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.filename}');
      await file.writeAsBytes(widget.bytes);
      await Share.shareXFiles([XFile(file.path)], text: widget.filename);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not share image')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: _opacity),
      body: GestureDetector(
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: Stack(
          children: [
            Center(
              child: Transform.translate(
                offset: Offset(0, _dragOffset),
                child: Opacity(
                  opacity: _opacity,
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.memory(widget.bytes, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.filename,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.timestamp != null)
                              Text(
                                formatMessageTime(widget.timestamp),
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share, color: Colors.white),
                        onPressed: _share,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
