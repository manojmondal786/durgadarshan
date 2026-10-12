import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Golden embers drifting up from the lower part of the screen, as if from
/// the aarti lamps in the splash artwork. Driven by [progress] from 0 to 1;
/// each ember rises and fades once, so the effect ends by itself.
class RisingEmbers extends StatelessWidget {
  const RisingEmbers({super.key, required this.progress});

  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _EmberPainter(progress),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Ember {
  _Ember(math.Random random)
    : x = 0.08 + random.nextDouble() * 0.84,
      y = 0.6 + random.nextDouble() * 0.32,
      rise = 0.22 + random.nextDouble() * 0.3,
      sway = 6 + random.nextDouble() * 14,
      phase = random.nextDouble() * math.pi * 2,
      radius = 1.4 + random.nextDouble() * 2.2,
      start = random.nextDouble() * 0.5,
      life = 0.4 + random.nextDouble() * 0.35,
      warm = random.nextBool();

  /// Start position as fractions of the canvas.
  final double x;
  final double y;

  /// How far it climbs, as a fraction of the height.
  final double rise;
  final double sway;
  final double phase;
  final double radius;

  /// When it appears and how long it lasts, as fractions of the run.
  final double start;
  final double life;
  final bool warm;
}

class _EmberPainter extends CustomPainter {
  _EmberPainter(this.progress) : super(repaint: progress);

  final Animation<double> progress;

  // Fixed seed: the same gentle pattern every launch.
  static final _embers = List.generate(24, (_) => _Ember(_random));
  static final _random = math.Random(11);

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final glow = Paint();
    final core = Paint();
    for (final ember in _embers) {
      final local = (t - ember.start) / ember.life;
      if (local <= 0 || local >= 1) continue;
      // Fade in quickly, then out as it rises.
      final alpha = math.sin(local * math.pi);
      final dx = math.sin(ember.phase + local * math.pi * 2) * ember.sway;
      final center = Offset(
        ember.x * size.width + dx,
        (ember.y - ember.rise * local) * size.height,
      );
      final color = ember.warm ? AppColors.marigold : AppColors.goldBright;
      glow.color = color.withValues(alpha: 0.22 * alpha);
      core.color = Color.lerp(
        color,
        Colors.white,
        0.35,
      )!.withValues(alpha: 0.9 * alpha);
      canvas
        ..drawCircle(center, ember.radius * 3.2, glow)
        ..drawCircle(center, ember.radius, core);
    }
  }

  @override
  bool shouldRepaint(_EmberPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
