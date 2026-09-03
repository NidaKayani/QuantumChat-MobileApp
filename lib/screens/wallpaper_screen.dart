import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../crypto/key_storage.dart';
import '../state/theme_controller.dart';
import '../theme/qc_theme.dart';

const _solidColors = <_WallpaperPreset>[
  _WallpaperPreset('solid:#1a1a2e', 'Midnight', Color(0xFF1a1a2e)),
  _WallpaperPreset('solid:#0f3460', 'Ocean', Color(0xFF0f3460)),
  _WallpaperPreset('solid:#16213e', 'Navy', Color(0xFF16213e)),
  _WallpaperPreset('solid:#1b1b2f', 'Dark Plum', Color(0xFF1b1b2f)),
  _WallpaperPreset('solid:#2d4059', 'Steel', Color(0xFF2d4059)),
  _WallpaperPreset('solid:#222831', 'Charcoal', Color(0xFF222831)),
  _WallpaperPreset('solid:#3a0ca3', 'Indigo', Color(0xFF3a0ca3)),
  _WallpaperPreset('solid:#006d77', 'Teal', Color(0xFF006d77)),
  _WallpaperPreset('solid:#370617', 'Wine', Color(0xFF370617)),
  _WallpaperPreset('solid:#344e41', 'Forest', Color(0xFF344e41)),
];

const _gradientPresets = <_GradientPreset>[
  _GradientPreset('gradient:aurora', 'Aurora', [Color(0xFF0f0c29), Color(0xFF302b63), Color(0xFF24243e)]),
  _GradientPreset('gradient:sunset', 'Sunset', [Color(0xFFf12711), Color(0xFFf5af19)]),
  _GradientPreset('gradient:ocean', 'Ocean', [Color(0xFF2193b0), Color(0xFF6dd5ed)]),
  _GradientPreset('gradient:berry', 'Berry', [Color(0xFF7b2ff7), Color(0xFFc471ed), Color(0xFFf64f59)]),
  _GradientPreset('gradient:emerald', 'Emerald', [Color(0xFF11998e), Color(0xFF38ef7d)]),
];

class WallpaperScreen extends StatefulWidget {
  const WallpaperScreen({super.key});

  @override
  State<WallpaperScreen> createState() => _WallpaperScreenState();
}

class _WallpaperScreenState extends State<WallpaperScreen> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = KeyStorage.instance.getWallpaper();
  }

  Future<void> _select(String? value) async {
    setState(() => _selected = value);
    if (value == null || value == 'default') {
      await KeyStorage.instance.clearWallpaper();
    } else {
      await KeyStorage.instance.setWallpaper(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeController>().colors;
    final isDefault = _selected == null || _selected == 'default';

    return Scaffold(
      appBar: AppBar(title: const Text('Chat Wallpaper')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SectionHeader(title: 'Default', colors: colors),
          _DefaultTile(selected: isDefault, colors: colors, onTap: () => _select(null)),
          const SizedBox(height: 20),
          _SectionHeader(title: 'Solid colors', colors: colors),
          _buildGrid(
            children: _solidColors.map((p) {
              final on = _selected == p.id;
              return _SwatchTile(color: p.color, label: p.label, selected: on, colors: colors, onTap: () => _select(p.id));
            }).toList(),
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: 'Gradients', colors: colors),
          _buildGrid(
            children: _gradientPresets.map((p) {
              final on = _selected == p.id;
              return _GradientTile(gradientColors: p.colors, label: p.label, selected: on, themeColors: colors, onTap: () => _select(p.id));
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid({required List<Widget> children}) {
    return Wrap(spacing: 12, runSpacing: 12, children: children);
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

class _DefaultTile extends StatelessWidget {
  const _DefaultTile({required this.selected, required this.colors, required this.onTap});
  final bool selected;
  final QcColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: colors.chat,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? colors.accent : colors.border, width: selected ? 2 : 1),
        ),
        child: Icon(Icons.format_paint_outlined, color: colors.textMuted),
      ),
      title: Text('Default', style: TextStyle(color: colors.textPrimary)),
      subtitle: Text('Use theme default', style: TextStyle(color: colors.textMuted, fontSize: 12)),
      trailing: selected ? Icon(Icons.check_circle, color: colors.accent) : null,
      onTap: onTap,
    );
  }
}

class _SwatchTile extends StatelessWidget {
  const _SwatchTile({required this.color, required this.label, required this.selected, required this.colors, required this.onTap});
  final Color color;
  final String label;
  final bool selected;
  final QcColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selected ? colors.accent : colors.border, width: selected ? 2.5 : 1),
              ),
              child: selected ? Icon(Icons.check, color: Colors.white.withValues(alpha: 0.9), size: 22) : null,
            ),
            const SizedBox(height: 5),
            Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 11), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _GradientTile extends StatelessWidget {
  const _GradientTile({required this.gradientColors, required this.label, required this.selected, required this.themeColors, required this.onTap});
  final List<Color> gradientColors;
  final String label;
  final bool selected;
  final QcColors themeColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradientColors),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selected ? themeColors.accent : themeColors.border, width: selected ? 2.5 : 1),
              ),
              child: selected ? Icon(Icons.check, color: Colors.white.withValues(alpha: 0.9), size: 22) : null,
            ),
            const SizedBox(height: 5),
            Text(label, style: TextStyle(color: themeColors.textSecondary, fontSize: 11), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _WallpaperPreset {
  const _WallpaperPreset(this.id, this.label, this.color);
  final String id;
  final String label;
  final Color color;
}

class _GradientPreset {
  const _GradientPreset(this.id, this.label, this.colors);
  final String id;
  final String label;
  final List<Color> colors;
}

/// Parse a stored wallpaper value into a BoxDecoration for the chat background.
BoxDecoration? wallpaperDecoration(String? value) {
  if (value == null || value.isEmpty || value == 'default') return null;
  if (value.startsWith('solid:')) {
    final hex = value.substring(6);
    final colorValue = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    if (colorValue != null) return BoxDecoration(color: Color(0xFF000000 | colorValue));
  }
  if (value.startsWith('gradient:')) {
    final name = value.substring(9);
    final preset = _gradientPresets.where((p) => p.id == value || p.id.endsWith(name)).firstOrNull;
    if (preset != null) {
      return BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: preset.colors),
      );
    }
  }
  return null;
}
