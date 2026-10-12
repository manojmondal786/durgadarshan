import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';

/// Page transition for every route: the new page rises a little and fades
/// in over the old one, which settles back slightly. Set in the theme, so
/// routes keep their platform behaviour (e.g. iOS keeps its own transition
/// and swipe-back).
class FestivePageTransitionsBuilder extends PageTransitionsBuilder {
  const FestivePageTransitionsBuilder();

  @override
  Duration get transitionDuration => AppMotion.route;

  @override
  Duration get reverseTransitionDuration => AppMotion.routeReverse;

  // Tweens driven straight off the route's animations: nothing to dispose.
  static final _fade = CurveTween(curve: AppMotion.standardCurve);
  static final _rise = Tween(
    begin: const Offset(0, 0.05),
    end: Offset.zero,
  ).chain(CurveTween(curve: AppMotion.standardCurve));
  static final _settle = Tween(
    begin: 1.0,
    end: 0.96,
  ).chain(CurveTween(curve: AppMotion.standardCurve));

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppMotion.reduced(context)) return child;
    return ScaleTransition(
      scale: secondaryAnimation.drive(_settle),
      child: FadeTransition(
        opacity: animation.drive(_fade),
        child: SlideTransition(position: animation.drive(_rise), child: child),
      ),
    );
  }
}
