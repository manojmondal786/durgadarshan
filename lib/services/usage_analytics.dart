import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'install_target_stub.dart'
    if (dart.library.js_interop) 'install_target_web.dart'
    as launch;

/// Counts installs and active users with Google Analytics for Firebase.
///
/// Only Firebase's automatic events are sent (first open, sessions,
/// engagement), plus how the app was launched. No location, pandal, visit
/// or personal data is ever logged, and advertising features are off.
abstract final class UsageAnalytics {
  /// Starts counting with [options], the Firebase app for this platform
  /// (null where none is set up, e.g. desktop). Never throws: without a
  /// connection, or if Firebase can't start, the app simply runs uncounted.
  static Future<void> start(FirebaseOptions? options) async {
    if (options == null) return;
    try {
      await Firebase.initializeApp(options: options);
      final analytics = FirebaseAnalytics.instance;
      await analytics.setConsent(
        analyticsStorageConsentGranted: true,
        adStorageConsentGranted: false,
        adUserDataConsentGranted: false,
        adPersonalizationSignalsConsentGranted: false,
      );
      await analytics.setUserProperty(name: 'launch_mode', value: launchMode);
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'durga_darshan',
          context: ErrorDescription('while starting usage analytics'),
        ),
      );
    }
  }

  /// How this copy of the app was opened, so reports can tell installs
  /// apart from browser visits: `android_app`, `home_screen` (the web app
  /// added to a phone's Home Screen) or `browser`.
  static String get launchMode {
    if (!kIsWeb) return '${defaultTargetPlatform.name}_app'.toLowerCase();
    return launch.isStandalone() ? 'home_screen' : 'browser';
  }
}
