import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 48});
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _LogoPainter(),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final r = Radius.circular(s * 0.28);
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2563EB), Color(0xFF3B82F6), Color(0xFF22D3EE)],
      ).createShader(Rect.fromLTWH(0, 0, s, s));
    canvas.drawRRect(RRect.fromLTRBR(0, 0, s, s, r), bg);

    final bubble = Path()
      ..moveTo(s * 0.28, s * 0.32)
      ..quadraticBezierTo(s * 0.28, s * 0.24, s * 0.38, s * 0.24)
      ..lineTo(s * 0.68, s * 0.24)
      ..quadraticBezierTo(s * 0.78, s * 0.24, s * 0.78, s * 0.34)
      ..lineTo(s * 0.78, s * 0.52)
      ..quadraticBezierTo(s * 0.78, s * 0.62, s * 0.66, s * 0.62)
      ..lineTo(s * 0.44, s * 0.62)
      ..lineTo(s * 0.32, s * 0.74)
      ..lineTo(s * 0.36, s * 0.62)
      ..lineTo(s * 0.38, s * 0.62)
      ..quadraticBezierTo(s * 0.28, s * 0.62, s * 0.28, s * 0.52)
      ..close();
    canvas.drawPath(bubble, Paint()..color = Colors.white.withValues(alpha: 0.95));

    final spark = Paint()
      ..color = const Color(0xFF22D3EE)
      ..strokeWidth = s * 0.06
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(s * 0.72, s * 0.72), Offset(s * 0.84, s * 0.60), spark);
    canvas.drawCircle(Offset(s * 0.84, s * 0.60), s * 0.045, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
