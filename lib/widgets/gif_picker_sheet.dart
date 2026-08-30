import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../state/auth_controller.dart';
import '../state/chat_controller.dart';
import '../state/theme_controller.dart';

Future<void> showGifPickerSheet(BuildContext context) async {
  final colors = context.read<ThemeController>().colors;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: colors.surface,
    builder: (ctx) => const _GifPickerBody(),
  );
}

class _GifPickerBody extends StatefulWidget {
  const _GifPickerBody();

  @override
  State<_GifPickerBody> createState() => _GifPickerBodyState();
}

class _GifPickerBodyState extends State<_GifPickerBody> {
  final query = TextEditingController(text: 'hello');
  List<Map<String, dynamic>> results = [];
  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final list = await context.read<AuthController>().api.searchGifs(query.text.trim());
      setState(() => results = list);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _send(Map<String, dynamic> gif) async {
    final url = (gif['url'] ?? gif['gifUrl'] ?? gif['previewUrl'] ?? gif['images']?['original']?['url'])?.toString();
    if (url == null || url.isEmpty) return;
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      if (res.statusCode >= 400) throw Exception('Download failed');
      if (!mounted) return;
      await context.read<ChatController>().sendAttachmentBytes(
            bytes: res.bodyBytes,
            filename: 'gif-${DateTime.now().millisecondsSinceEpoch}.gif',
            mimetype: 'image/gif',
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('GIF failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeController>().colors;
    final height = MediaQuery.of(context).size.height * 0.65;
    return SizedBox(
      height: height,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(99))),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: query,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Search GIFs',
                suffixIcon: IconButton(onPressed: _search, icon: const Icon(Icons.search)),
              ),
            ),
          ),
          if (loading) const LinearProgressIndicator(minHeight: 2),
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(error!, style: TextStyle(color: colors.error)),
            ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: results.length,
              itemBuilder: (context, i) {
                final g = results[i];
                final preview = (g['previewUrl'] ?? g['url'] ?? g['gifUrl'] ?? '').toString();
                return InkWell(
                  onTap: () => _send(g),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: preview.isEmpty
                        ? Container(color: colors.elevated, child: const Icon(Icons.gif_box_outlined))
                        : Image.network(preview, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: colors.elevated)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
