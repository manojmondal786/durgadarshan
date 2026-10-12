import 'package:flutter/widgets.dart';

/// For screens that reveal their content when it first appears.
///
/// [revealing] is true only while a reveal frame is built. Pass it to
/// `Entrance.enabled` so items built later, e.g. scrolled into view, simply
/// appear instead of animating in on their own.
mixin FirstReveal<T extends StatefulWidget> on State<T> {
  bool _revealing = true;

  bool get revealing => _revealing;

  @override
  void initState() {
    super.initState();
    _endRevealAfterFrame();
  }

  /// Reveals whatever is built in the next frame, e.g. new search results.
  void revealNextFrame() {
    _revealing = true;
    _endRevealAfterFrame();
  }

  void _endRevealAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealing = false);
  }
}
