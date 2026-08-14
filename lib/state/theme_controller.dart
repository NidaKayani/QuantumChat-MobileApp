import 'package:flutter/material.dart';

import '../crypto/key_storage.dart';
import 'qc_theme.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this.storage);

  final KeyStorage storage;
  QcThemeId id = QcThemeId.dark;

  QcColors get colors => QcColors.of(id);

  Future<void> load() async {
    final stored = storage.getThemeId();
    switch (stored) {
      case 'light':
        id = QcThemeId.light;
        break;
      case 'eyecare':
        id = QcThemeId.eyecare;
        break;
      default:
        id = QcThemeId.dark;
    }
    notifyListeners();
  }

  Future<void> setTheme(QcThemeId next) async {
    id = next;
    await storage.setThemeId(next.name);
    notifyListeners();
  }

  Future<void> cycle() async {
    switch (id) {
      case QcThemeId.dark:
        await setTheme(QcThemeId.light);
        break;
      case QcThemeId.light:
        await setTheme(QcThemeId.eyecare);
        break;
      case QcThemeId.eyecare:
        await setTheme(QcThemeId.dark);
        break;
    }
  }
}
