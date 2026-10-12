import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Safari's own flag for a page launched from the Home Screen.
@JS('navigator.standalone')
external bool? get _iosStandalone;

/// Whether the web app was launched from the Home Screen, i.e. installed.
bool isStandalone() =>
    web.window.matchMedia('(display-mode: standalone)').matches ||
    (_iosStandalone ?? false);
