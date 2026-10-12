import 'package:flutter/widgets.dart';

abstract final class Breakpoints {
  /// Two-column pandal list from here.
  static const medium = 720.0;

  /// Navigation rail instead of a bottom bar from here.
  static const expanded = 840.0;

  static const maxContentWidth = 960.0;
}

/// Centres [child] at full available width, capped at [maxWidth] so content
/// stays readable on tablets and desktop browsers. Takes only the height its
/// child needs.
class ContentWidth extends StatelessWidget {
  const ContentWidth({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.maxContentWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
