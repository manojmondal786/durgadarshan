import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Gold rule with a central diamond, used between sections.
class OrnamentalDivider extends StatelessWidget {
  const OrnamentalDivider({super.key, this.color = AppColors.gold});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: 16,
        width: double.infinity,
        child: CustomPaint(painter: _DividerPainter(color)),
      ),
    );
  }
}

class _DividerPainter extends CustomPainter {
  _DividerPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final fill = Paint()..color = color;

    for (final side in const [-1.0, 1.0]) {
      final from = Offset(cx + side * 22, cy);
      final to = Offset(side < 0 ? 0 : size.width, cy);
      canvas.drawLine(
        from,
        to,
        Paint()
          ..strokeWidth = 1.2
          ..shader = LinearGradient(colors: [color, color.withValues(alpha: 0)])
              .createShader(Rect.fromPoints(from, to)),
      );
      canvas.drawCircle(Offset(cx + side * 14, cy), 2.2, fill);
    }

    final diamond = Path()
      ..moveTo(cx, cy - 6)
      ..lineTo(cx + 6, cy)
      ..lineTo(cx, cy + 6)
      ..lineTo(cx - 6, cy)
      ..close();
    canvas.drawPath(diamond, fill);
    canvas.drawCircle(Offset(cx, cy), 1.6, Paint()..color = AppColors.ivory);
  }

  @override
  bool shouldRepaint(_DividerPainter oldDelegate) => oldDelegate.color != color;
}
