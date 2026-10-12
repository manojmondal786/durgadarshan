import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';

/// Reveals [child] once, when it is first built: it fades in while sliding
/// from [offset] and growing from [beginScale].
///
/// The [delay] is part of the same animation rather than a timer, so a
/// staggered list is a single run of frames. With reduced motion the child
/// simply appears.
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.entrance,
    this.offset = const Offset(0, 16),
    this.beginScale = 1,
    this.curve = AppMotion.standardCurve,
    this.enabled = true,
  });

  /// Item [index] of a list revealed one after another.
  Entrance.staggered({
    super.key,
    required int index,
    required this.child,
    Duration start = Duration.zero,
    this.duration = AppMotion.entrance,
    this.offset = const Offset(0, 16),
    this.beginScale = 1,
    this.curve = AppMotion.standardCurve,
    this.enabled = true,
  }) : delay = AppMotion.staggerDelay(index, start: start);

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Where the child starts, in logical pixels from its place.
  final Offset offset;
  final double beginScale;
  final Curve curve;

  /// When false the child is shown as is, e.g. for items built after a
  /// screen's first reveal.
  final bool enabled;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _progress;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final total = widget.delay + widget.duration;
    _controller = AnimationController(vsync: this, duration: total);
    final start = total == Duration.zero
        ? 0.0
        : widget.delay.inMicroseconds / total.inMicroseconds;
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: widget.curve),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!widget.enabled || AppMotion.reduced(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The same widgets wrap the child before, during and after the reveal,
    // so finishing it never rebuilds the child's subtree.
    return AnimatedBuilder(
      animation: _progress,
      child: widget.child,
      builder: (context, child) {
        final t = _progress.value;
        final scale = widget.beginScale + (1 - widget.beginScale) * t;
        final offset = widget.offset * (1 - t);
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(scale, scale, 1)
              ..setTranslationRaw(offset.dx, offset.dy, 0),
            child: child,
          ),
        );
      },
    );
  }
}
