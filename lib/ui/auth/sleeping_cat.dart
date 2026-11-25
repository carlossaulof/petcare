import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Ilustração vetorial do gatinho dormindo (desenhada em código, sem assets).
class SleepingCat extends StatefulWidget {
  const SleepingCat({super.key, this.size = 220});
  final double size;

  @override
  State<SleepingCat> createState() => _SleepingCatState();
}

class _SleepingCatState extends State<SleepingCat> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => CustomPaint(
        size: Size(widget.size, widget.size * 0.72),
        painter: _CatPainter(breath: _c.value),
      ),
    );
  }
}

class _CatPainter extends CustomPainter {
  _CatPainter({required this.breath});
  final double breath;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fur = Paint()..color = const Color(0xFF8E8F99);
    final furDark = Paint()..color = const Color(0xFF6D6E78);
    final white = Paint()..color = Colors.white;
    final pink = Paint()..color = const Color(0xFFF1B6C0);
    final line = Paint()
      ..color = const Color(0xFF3B3C44)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.009
      ..strokeCap = StrokeCap.round;

    // sombra
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.9), width: w * 0.8, height: h * 0.12),
      Paint()..color = Colors.black.withOpacity(0.06),
    );
    // almofada
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.74), width: w * 0.86, height: h * 0.34),
        Paint()..color = const Color(0xFF2F3A30));
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.72), width: w * 0.74, height: h * 0.24),
        Paint()..color = const Color(0xFF55604F));

    final rise = breath * h * 0.015;
    // rabo
    final tail = Path()
      ..moveTo(w * 0.78, h * 0.66)
      ..quadraticBezierTo(w * 0.9, h * 0.78, w * 0.62, h * 0.8)
      ..quadraticBezierTo(w * 0.5, h * 0.81, w * 0.4, h * 0.78);
    canvas.drawPath(
        tail,
        Paint()
          ..color = const Color(0xFF7B7C86)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.06
          ..strokeCap = StrokeCap.round);

    // corpo
    final body = Rect.fromCenter(
        center: Offset(w * 0.58, h * 0.56 - rise), width: w * 0.5, height: h * 0.36 + rise * 2);
    canvas.drawOval(body, fur);
    // listras
    for (var i = 0; i < 4; i++) {
      final x = w * (0.5 + i * 0.07);
      canvas.drawArc(Rect.fromCenter(center: Offset(x, h * 0.48 - rise), width: w * 0.05, height: h * 0.2), 3.6,
          1.4, false, line..color = furDark.color);
    }
    line.color = const Color(0xFF3B3C44);

    // cabeça
    final head = Offset(w * 0.33, h * 0.56);
    final r = w * 0.13;
    final earL = Path()
      ..moveTo(head.dx - r * 0.95, head.dy - r * 0.3)
      ..lineTo(head.dx - r * 0.75, head.dy - r * 1.45)
      ..lineTo(head.dx - r * 0.1, head.dy - r * 0.8)
      ..close();
    final earR = Path()
      ..moveTo(head.dx + r * 0.1, head.dy - r * 0.85)
      ..lineTo(head.dx + r * 0.75, head.dy - r * 1.45)
      ..lineTo(head.dx + r * 0.95, head.dy - r * 0.3)
      ..close();
    canvas.drawPath(earL, fur);
    canvas.drawPath(earR, fur);
    canvas.drawPath(
        Path()
          ..moveTo(head.dx - r * 0.8, head.dy - r * 0.5)
          ..lineTo(head.dx - r * 0.7, head.dy - r * 1.15)
          ..lineTo(head.dx - r * 0.3, head.dy - r * 0.8)
          ..close(),
        pink);
    canvas.drawPath(
        Path()
          ..moveTo(head.dx + r * 0.3, head.dy - r * 0.8)
          ..lineTo(head.dx + r * 0.7, head.dy - r * 1.15)
          ..lineTo(head.dx + r * 0.8, head.dy - r * 0.5)
          ..close(),
        pink);
    canvas.drawCircle(head, r, fur);
    // focinho branco
    canvas.drawOval(Rect.fromCenter(center: Offset(head.dx, head.dy + r * 0.45), width: r * 1.1, height: r * 0.75),
        white);
    // olhos fechados
    canvas.drawArc(Rect.fromCenter(center: Offset(head.dx - r * 0.4, head.dy - r * 0.05), width: r * 0.45, height: r * 0.3),
        0, 3.14, false, line);
    canvas.drawArc(Rect.fromCenter(center: Offset(head.dx + r * 0.4, head.dy - r * 0.05), width: r * 0.45, height: r * 0.3),
        0, 3.14, false, line);
    // nariz
    canvas.drawCircle(Offset(head.dx, head.dy + r * 0.25), r * 0.08, pink);
    // patinhas
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.44, h * 0.71), width: w * 0.12, height: h * 0.08), white);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.52, h * 0.72), width: w * 0.11, height: h * 0.07), white);

    // Zzz
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < 3; i++) {
      tp.text = TextSpan(
        text: 'z',
        style: TextStyle(
          color: AppColors.muted.withOpacity(0.5 + breath * 0.4),
          fontSize: w * (0.05 + i * 0.015),
          fontWeight: FontWeight.w700,
        ),
      );
      tp.layout();
      tp.paint(canvas, Offset(w * (0.36 + i * 0.03), h * (0.2 - i * 0.08) - breath * 4));
    }
  }

  @override
  bool shouldRepaint(covariant _CatPainter old) => old.breath != breath;
}
