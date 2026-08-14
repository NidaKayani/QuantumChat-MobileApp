import 'package:flutter/material.dart';

enum QcThemeId {
  dark,
  light,
  eyecare,
}

class QcColors {
  const QcColors({
    required this.body,
    required this.surface,
    required this.elevated,
    required this.input,
    required this.chat,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.accentHover,
    required this.accentCyan,
    required this.accentMuted,
    required this.bubbleMine,
    required this.bubbleMineFg,
    required this.bubbleTheirs,
    required this.bubbleTheirsFg,
    required this.error,
    required this.success,
    required this.overlay,
  });

  final Color body;
  final Color surface;
  final Color elevated;
  final Color input;
  final Color chat;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color accentHover;
  final Color accentCyan;
  final Color accentMuted;
  final Color bubbleMine;
  final Color bubbleMineFg;
  final Color bubbleTheirs;
  final Color bubbleTheirsFg;
  final Color error;
  final Color success;
  final Color overlay;

  bool get isDark => body.computeLuminance() < 0.45;

  static const dark = QcColors(
    body: Color(0xFF07131F),
    surface: Color(0xFF0D1B2A),
    elevated: Color(0xFF16263D),
    input: Color(0xD916263D),
    chat: Color(0xFF102033),
    border: Color(0xFF223248),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF64748B),
    accent: Color(0xFF3B82F6),
    accentHover: Color(0xFF2563EB),
    accentCyan: Color(0xFF22D3EE),
    accentMuted: Color(0x283B82F6),
    bubbleMine: Color(0xFF2563EB),
    bubbleMineFg: Color(0xFFFFFFFF),
    bubbleTheirs: Color(0xFF1A2D45),
    bubbleTheirsFg: Color(0xFFF1F5F9),
    error: Color(0xFFEF4444),
    success: Color(0xFF22C55E),
    overlay: Color(0xB807131F),
  );

  static const light = QcColors(
    body: Color(0xFFF4F9FF),
    surface: Color(0xFFFFFFFF),
    elevated: Color(0xFFF8FBFF),
    input: Color(0xEBFFFFFF),
    chat: Color(0xFFF8FBFF),
    border: Color(0xFFD7E3F4),
    textPrimary: Color(0xFF1E293B),
    textSecondary: Color(0xFF64748B),
    textMuted: Color(0xFF94A3B8),
    accent: Color(0xFF3B82F6),
    accentHover: Color(0xFF2563EB),
    accentCyan: Color(0xFF38BDF8),
    accentMuted: Color(0x1F3B82F6),
    bubbleMine: Color(0xFF2563EB),
    bubbleMineFg: Color(0xFFFFFFFF),
    bubbleTheirs: Color(0xFFE8F1FB),
    bubbleTheirsFg: Color(0xFF1E293B),
    error: Color(0xFFDC2626),
    success: Color(0xFF16A34A),
    overlay: Color(0x99071B2F),
  );

  static const eyecare = QcColors(
    body: Color(0xFF15130F),
    surface: Color(0xFF1E1B15),
    elevated: Color(0xFF28241C),
    input: Color(0xD928241C),
    chat: Color(0xFF1B1914),
    border: Color(0xFF3A3428),
    textPrimary: Color(0xFFE6DFD3),
    textSecondary: Color(0xFFB5AA9A),
    textMuted: Color(0xFF8A7F6E),
    accent: Color(0xFFD97706),
    accentHover: Color(0xFFB45309),
    accentCyan: Color(0xFFFBBF24),
    accentMuted: Color(0x24D97706),
    bubbleMine: Color(0xFFB45309),
    bubbleMineFg: Color(0xFFFFF7ED),
    bubbleTheirs: Color(0xFF2A251C),
    bubbleTheirsFg: Color(0xFFE6DFD3),
    error: Color(0xFFF87171),
    success: Color(0xFF4ADE80),
    overlay: Color(0xB815130F),
  );

  static QcColors of(QcThemeId id) {
    switch (id) {
      case QcThemeId.light:
        return light;
      case QcThemeId.eyecare:
        return eyecare;
      case QcThemeId.dark:
        return dark;
    }
  }
}

class QcTheme {
  static ThemeData material(QcColors c) {
    final scheme = c.isDark ? Brightness.dark : Brightness.light;
    return ThemeData(
      useMaterial3: true,
      brightness: scheme,
      scaffoldBackgroundColor: c.body,
      colorScheme: ColorScheme(
        brightness: scheme,
        primary: c.accent,
        onPrimary: Colors.white,
        secondary: c.accentCyan,
        onSecondary: c.body,
        error: c.error,
        onError: Colors.white,
        surface: c.surface,
        onSurface: c.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: c.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      dividerColor: c.border,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.elevated,
        contentTextStyle: TextStyle(color: c.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.input,
        hintStyle: TextStyle(color: c.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.accent, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.accent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return c.accent;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: c.border),
      ),
    );
  }
}
