import 'package:flutter/foundation.dart';

import 'install_target_stub.dart'
    if (dart.library.js_interop) 'install_target_web.dart'
    as launch;

/// How someone using the web version in a phone's browser can get the app.
enum InstallTarget {
  /// iPhone or iPad: browsers there offer no install popup, only Share →
  /// Add to Home Screen.
  iosHomeScreen,

  /// Android: the full Android app, which also has nearby alerts.
  androidApp,
}

/// What to suggest, or null unless this is the web version open in a
/// phone's browser rather than launched from the Home Screen.
InstallTarget? detectInstallTarget() {
  if (!kIsWeb || launch.isStandalone()) return null;
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => InstallTarget.iosHomeScreen,
    TargetPlatform.android => InstallTarget.androidApp,
    TargetPlatform.fuchsia ||
    TargetPlatform.linux ||
    TargetPlatform.macOS ||
    TargetPlatform.windows => null,
  };
}
