import 'package:flutter/material.dart';

import '../crypto/key_storage.dart';
import '../theme/qc_app_icons.dart';
import '../theme/qc_theme.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this.storage);

  final KeyStorage storage;
  QcThemeId id = QcThemeId.dark;
  QcAppIcon appIcon = QcAppIcon.original;

  QcColors get colors => QcColors.of(id);
  bool get isFunTheme => id.isFunTheme;
  bool get isDark => !id.isLightLike;
  String get logoAsset => appIcon.asset;

  Future<void> load() async {
    id = QcThemeIdX.tryParse(storage.getThemeId()) ?? QcThemeId.dark;
    appIcon = QcAppIcon.byId(storage.getAppIconId());
    notifyListeners();
  }

  Future<void> setTheme(QcThemeId next) async {
    if (id == next) return;
    id = next;
    await storage.setThemeId(next.name);
    notifyListeners();
  }

  Future<void> setAppIcon(QcAppIcon next) async {
    if (appIcon.id == next.id) return;
    appIcon = next;
    await storage.setAppIconId(next.id);
    notifyListeners();
  }

  /// Same 3-way flip as the website ThemeToggle: Light → Eyecare → Dark.
  /// Fun skins are not part of this cycle.
  Future<void> cycle() async {
    switch (id) {
      case QcThemeId.dark:
        await setTheme(QcThemeId.light);
      case QcThemeId.light:
        await setTheme(QcThemeId.eyecare);
      case QcThemeId.eyecare:
        await setTheme(QcThemeId.dark);
      default:
        await setTheme(QcThemeId.dark);
    }
  }
}
