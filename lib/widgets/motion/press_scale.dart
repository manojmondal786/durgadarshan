import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';

/// Shrinks [child] slightly while a pointer is down on it, as touch
/// feedback for cards and tiles. It only listens, so taps still reach the
/// child's own [InkWell].
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.scale = 0.97});

  final Widget child;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _set(bool pressed) {
    if (pressed != _pressed) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return widget.child;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: AppMotion.press,
        curve: AppMotion.standardCurve,
        child: widget.child,
      ),
    );
  }
}
