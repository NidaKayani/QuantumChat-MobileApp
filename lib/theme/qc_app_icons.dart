import 'package:flutter/material.dart';

/// Same app-icon variants as the website (`APP_ICONS` in ThemeContext.jsx).
class QcAppIcon {
  const QcAppIcon({
    required this.id,
    required this.label,
    required this.asset,
    required this.swatch,
  });

  final String id;
  final String label;
  final String asset;
  final Color swatch;

  static const original = QcAppIcon(
    id: 'original',
    label: 'Original',
    asset: 'assets/icons/original.png',
    swatch: Color(0xFF7DD3FC),
  );

  static const all = <QcAppIcon>[
    original,
    QcAppIcon(id: 'emerald', label: 'Emerald', asset: 'assets/icons/emerald.png', swatch: Color(0xFF6EE7B7)),
    QcAppIcon(id: 'violet', label: 'Violet', asset: 'assets/icons/violet.png', swatch: Color(0xFFC4B5FD)),
    QcAppIcon(id: 'sunset', label: 'Sunset', asset: 'assets/icons/sunset.png', swatch: Color(0xFFFDBA74)),
    QcAppIcon(id: 'rose', label: 'Rose', asset: 'assets/icons/rose.png', swatch: Color(0xFFF9A8D4)),
    QcAppIcon(id: 'crimson', label: 'Crimson', asset: 'assets/icons/crimson.png', swatch: Color(0xFFFCA5A5)),
    QcAppIcon(id: 'gold', label: 'Gold', asset: 'assets/icons/gold.png', swatch: Color(0xFFFCD34D)),
    QcAppIcon(id: 'lime', label: 'Lime', asset: 'assets/icons/lime.png', swatch: Color(0xFFBEF264)),
    QcAppIcon(id: 'mono-dark', label: 'Mono Dark', asset: 'assets/icons/mono-dark.png', swatch: Color(0xFFD1D5DB)),
    QcAppIcon(id: 'mono-light', label: 'Mono Light', asset: 'assets/icons/mono-light.png', swatch: Color(0xFFF9FAFB)),
    QcAppIcon(id: 'cyber', label: 'Cyber', asset: 'assets/icons/cyber.png', swatch: Color(0xFF67E8F9)),
  ];

  static QcAppIcon byId(String? id) {
    for (final icon in all) {
      if (icon.id == id) return icon;
    }
    return original;
  }
}
