import 'package:flutter/material.dart';

/// Offline, scalable two-tone icons. No images, fonts or network packages.
class JewelIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final bool selected;
  final int? navigationIndex;

  const JewelIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
    this.selected = false,
    this.navigationIndex,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = Color.lerp(color, Colors.white, dark ? 0.30 : 0.05)!;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: dark ? 0.28 : 0.14),
                color.withValues(alpha: dark ? 0.10 : 0.05),
              ],
            ),
            border: Border.all(color: accent.withValues(alpha: selected ? 0.50 : 0.20)),
          ),
          child: Stack(alignment: Alignment.center, children: [
            Positioned(
              top: size * 0.13,
              right: size * 0.13,
              child: Container(
                width: size * 0.12,
                height: size * 0.12,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4C96A).withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            if (navigationIndex != null)
              CustomPaint(
                size: Size.square(size * 0.65),
                painter: _NavigationGlyph(navigationIndex!, accent),
              )
            else ...[
              Transform.translate(
                offset: Offset(size * 0.035, size * 0.035),
                child: Icon(icon, size: size * 0.55, color: color.withValues(alpha: 0.20)),
              ),
              Icon(icon, size: size * 0.55, color: accent),
            ],
          ]),
        ),
      ),
    );
  }
}

/// Six original navigation illustrations drawn on a 24-unit grid.
class _NavigationGlyph extends CustomPainter {
  final int index;
  final Color color;
  const _NavigationGlyph(this.index, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color.withValues(alpha: 0.22);
    final gold = Paint()..color = const Color(0xFFF4C96A);
    void line(double x, double y, double a, double b) =>
        canvas.drawLine(Offset(x, y), Offset(a, b), stroke);
    void box(double x, double y, double w, double h) {
      final shape = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(2));
      canvas.drawRRect(shape, fill);
      canvas.drawRRect(shape, stroke);
    }
    switch (index) {
      case 0:
        final house = Path()..moveTo(3, 10)..lineTo(12, 3)..lineTo(21, 10)
          ..lineTo(21, 20)..quadraticBezierTo(21, 21, 19, 21)
          ..lineTo(5, 21)..quadraticBezierTo(3, 21, 3, 20)..close();
        canvas.drawPath(house, fill);
        canvas.drawPath(house, stroke);
        box(9, 13, 6, 8);
        canvas.drawCircle(const Offset(12, 9), 1.6, gold);
        break;
      case 1:
        box(5, 3, 14, 18);
        line(9, 8, 15, 8);
        line(9, 12, 13, 12);
        canvas.drawCircle(const Offset(17, 17), 4.5, gold);
        line(17, 15, 17, 17);
        line(17, 17, 19, 18);
        break;
      case 2:
        box(3, 13, 4, 8);
        box(10, 9, 4, 12);
        box(17, 4, 4, 17);
        canvas.drawCircle(const Offset(5, 6), 2, gold);
        break;
      case 3:
        canvas.drawCircle(const Offset(12, 12), 9, fill);
        canvas.drawCircle(const Offset(12, 12), 9, stroke);
        canvas.drawCircle(const Offset(12, 12), 5, stroke);
        canvas.drawCircle(const Offset(12, 12), 2, gold);
        line(13, 11, 20, 4);
        line(17, 4, 20, 4);
        line(20, 4, 20, 7);
        break;
      case 4:
        final star = Path()..moveTo(12, 2)..lineTo(15, 8)..lineTo(22, 9)
          ..lineTo(17, 14)..lineTo(18, 21)..lineTo(12, 18)
          ..lineTo(6, 21)..lineTo(7, 14)..lineTo(2, 9)..lineTo(9, 8)..close();
        canvas.drawPath(star, fill);
        canvas.drawPath(star, stroke);
        canvas.drawCircle(const Offset(12, 12), 2.2, gold);
        break;
      default:
        box(4, 3, 15, 18);
        line(8, 8, 15, 8);
        line(8, 12, 13, 12);
        final pen = Path()..moveTo(13, 19)..lineTo(15, 14)
          ..lineTo(21, 8)..lineTo(23, 10)..lineTo(17, 16)..close();
        canvas.drawPath(pen, gold);
        canvas.drawPath(pen, stroke);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NavigationGlyph oldDelegate) =>
      oldDelegate.index != index || oldDelegate.color != color;
}
