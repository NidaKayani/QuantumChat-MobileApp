import 'package:flutter/material.dart';

/// Same brand mark as the web app (`frontend/public/logo.png`).
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 48});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo.png',
      width: size,
      height: size,
      filterQuality: FilterQuality.high,
      semanticLabel: 'QuantumChat',
    );
  }
}
