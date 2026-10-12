import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';

/// Maroon-and-gold map pin. Its tip is at the bottom centre, so place it
/// with `Alignment.topCenter`. Pandals sharing one spot get a count badge.
class PandalPin extends StatelessWidget {
  const PandalPin({
    super.key,
    required this.label,
    required this.onTap,
    this.count = 1,
    this.selected = false,
  });

  static const size = Size(44, 54);

  final String label;
  final VoidCallback onTap;
  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: selected ? 1.18 : 1,
          alignment: Alignment.bottomCenter,
          duration: AppMotion.duration(context, AppMotion.quick),
          curve: AppMotion.popCurve,
          child: Stack(
            children: [
              CustomPaint(size: size, painter: _PinPainter(selected)),
              if (count > 1)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.marigoldYellow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.maroon, width: 1.5),
                    ),
                    child: Text(
                      '$count',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.maroonDeep,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The user's parked vehicle: a gold car on maroon, as the app's buttons.
class ParkedVehicleMarker extends StatelessWidget {
  const ParkedVehicleMarker({
    super.key,
    required this.onTap,
    this.selected = false,
  });

  static const size = 46.0;

  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Your parked vehicle',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: selected ? 1.15 : 1,
          duration: AppMotion.duration(context, AppMotion.quick),
          curve: AppMotion.popCurve,
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.headerGradient,
              border: Border.all(
                color: selected ? AppColors.goldBright : AppColors.gold,
                width: 2.5,
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 5),
              ],
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              color: AppColors.goldBright,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

/// "You are here" dot, shown while nearby alerts are on.
class UserLocationDot extends StatelessWidget {
  const UserLocationDot({super.key});

  static const size = 36.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Your location',
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.marigold.withValues(alpha: 0.25),
        ),
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.vermilion,
            border: Border.all(color: AppColors.ivory, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
        ),
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  _PinPainter(this.selected);

  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final r = size.width * 0.4;
    final cy = r + 3;
    final head = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    final tail = Path()
      ..moveTo(cx - r * 0.72, cy + r * 0.69)
      ..lineTo(cx, size.height - 2)
      ..lineTo(cx + r * 0.72, cy + r * 0.69)
      ..close();
    final pin = Path.combine(PathOperation.union, head, tail);

    canvas
      ..drawShadow(pin, Colors.black, 3, false)
      ..drawPath(
        pin,
        Paint()..color = selected ? AppColors.vermilion : AppColors.maroon,
      )
      ..drawPath(
        pin,
        Paint()
          ..color = AppColors.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      )
      ..drawCircle(Offset(cx, cy), r * 0.52, Paint()..color = AppColors.ivory)
      ..drawCircle(
        Offset(cx, cy),
        r * 0.3,
        Paint()..color = AppColors.marigold,
      );
  }

  @override
  bool shouldRepaint(_PinPainter oldDelegate) =>
      oldDelegate.selected != selected;
}
