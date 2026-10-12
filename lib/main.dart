import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/usage_analytics.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Counted in the background, so the splash never waits for it.
  unawaited(UsageAnalytics.start(DefaultFirebaseOptions.currentPlatform));
  runApp(const DurgaDarshanApp());
}
