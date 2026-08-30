import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/theme_controller.dart';
import '../theme/qc_app_icons.dart';

/// Same brand mark as the web app. Uses the selected app-icon variant.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 48});
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = context.select<ThemeController, String>((t) => t.logoAsset);

    return Image.asset(
      asset,
      width: size,
      height: size,
      filterQuality: FilterQuality.high,
      semanticLabel: 'QuantumChat',
      errorBuilder: (_, __, ___) => Image.asset(
        QcAppIcon.original.asset,
        width: size,
        height: size,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
