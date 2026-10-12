import 'package:flutter/widgets.dart';

/// Motion tokens. Every animation takes its timing and curve from here, so
/// motion stays consistent and the system "remove animations" setting is
/// honoured in one place.
///
/// The reusable building blocks live in `lib/widgets/motion/`: `Entrance`
/// for one-shot reveals, `PressScale` for touch feedback, the page
/// transition used by every route, and the splash embers. All of them check
/// [reduced] and show their end state straight away when it is true.
///
/// Animations are one-shot: nothing loops forever, which keeps the battery
/// happy and lets tests settle.
abstract final class AppMotion {
  /// Touch feedback.
  static const press = Duration(milliseconds: 120);

  /// Small state changes: chip selection, icon swaps.
  static const quick = Duration(milliseconds: 180);

  /// Most transitions: banners, overlays, switching tabs.
  static const standard = Duration(milliseconds: 250);

  /// Opening and closing a page.
  static const route = Duration(milliseconds: 380);
  static const routeReverse = Duration(milliseconds: 280);

  /// One element revealing itself.
  static const entrance = Duration(milliseconds: 460);

  /// Gap between consecutive items of a staggered reveal.
  static const stagger = Duration(milliseconds: 55);

  /// Items after this many are revealed together, so long lists don't drag.
  static const maxStaggeredItems = 8;

  /// Larger changes, such as leaving the splash.
  static const emphasized = Duration(milliseconds: 450);

  /// How long the splash stays up, at least, on a cold start. Long enough
  /// for its reveal to finish and be seen.
  static const splashMinimum = Duration(milliseconds: 2400);

  /// The splash's own reveal and rising embers.
  static const splashIntro = Duration(milliseconds: 2400);

  static const standardCurve = Curves.easeOutCubic;
  static const exitCurve = Curves.easeInCubic;

  /// A small overshoot for playful feedback, e.g. the favourite heart.
  static const popCurve = Curves.easeOutBack;

  /// True when the platform asks for animations to be reduced.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [value], or zero when animations should be reduced.
  static Duration duration(BuildContext context, Duration value) =>
      reduced(context) ? Duration.zero : value;

  /// Delay before item [index] of a staggered reveal.
  static Duration staggerDelay(int index, {Duration start = Duration.zero}) =>
      start + stagger * index.clamp(0, maxStaggeredItems);
}
