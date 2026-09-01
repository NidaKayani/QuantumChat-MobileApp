import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// QuantumChat API origin (no trailing slash, no `/api` suffix).
/// Override at build time: `--dart-define=API_URL=https://your-api.example`
/// or from Settings on device.
class AppConfig {
  static const _defined = String.fromEnvironment('API_URL');
  static const productionFallback = 'https://quantum-chat-backend-six.vercel.app';

  /// Android emulator reaches the host machine at 10.0.2.2.
  static String get defaultApiBase {
    if (_defined.isNotEmpty) return _defined.replaceAll(RegExp(r'/$'), '');
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:5000';
    return 'http://localhost:5000';
  }

  static String apiUrl(String base) => '${base.replaceAll(RegExp(r'/$'), '')}/api';

  static String signalUrl(String base) {
    if (base.contains('vercel.app')) return '';
    return base.replaceAll(RegExp(r'/$'), '');
  }

  static String deviceLabel() {
    final os = kIsWeb
        ? 'Web'
        : Platform.isIOS
            ? 'iOS'
            : Platform.isAndroid
                ? 'Android'
                : Platform.operatingSystem;
    final label = 'QuantumChat $os';
    return label.length <= 120 ? label : label.substring(0, 120);
  }
}
