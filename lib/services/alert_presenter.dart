import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/proximity.dart';
import '../theme/app_colors.dart';

/// Shows "pandal nearby" alerts as system notifications, the only way the
/// app alerts. Behind an interface so tests never touch the platform plugin.
abstract interface class AlertPresenter {
  /// Sets notifications up, so that tapping one calls [onOpen] with its
  /// pandal's id, and returns whether they can be shown.
  ///
  /// With [askPermission] it asks for permission if needed; call it so only
  /// straight after a tap, as browsers require. Otherwise it only checks.
  Future<bool> prepare({
    required void Function(String pandalId) onOpen,
    bool askPermission = true,
  });

  /// The pandal whose notification was tapped to launch the app, if any.
  Future<String?> launchPandalId();

  Future<void> show(NearbyPandal nearest, {required int othersNearby});
}

class LocalNotificationPresenter implements AlertPresenter {
  LocalNotificationPresenter();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  void Function(String pandalId)? _onOpen;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'nearby_pandals',
      'Nearby pandals',
      channelDescription: 'Alerts when a pandal is within 3 km',
      importance: Importance.high,
      priority: Priority.high,
      // Tints the white temple icon in the notification shade.
      color: AppColors.maroon,
    ),
    // Shown as a banner even while the app is open: there is no in-app alert.
    iOS: DarwinNotificationDetails(presentBanner: true, presentList: true),
  );

  @override
  Future<bool> prepare({
    required void Function(String pandalId) onOpen,
    bool askPermission = true,
  }) async {
    _onOpen = onOpen;
    try {
      await _initialize();
      final granted = askPermission
          ? await _requestPermission()
          : await _hasPermission();
      return granted ?? false;
    } catch (_) {
      // Unsupported platform or plugin failure.
      return false;
    }
  }

  Future<void> _initialize() async {
    if (_initialized) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        // A white-on-transparent status bar icon, as Android requires;
        // see android/app/src/main/res/drawable/ic_stat_pandal.xml.
        android: AndroidInitializationSettings('ic_stat_pandal'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        web: WebInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        final id = response.payload;
        if (id != null && id.isNotEmpty) _onOpen?.call(id);
      },
    );
    _initialized = true;
  }

  Future<bool?> _requestPermission() async =>
      await _android?.requestNotificationsPermission() ??
      await _ios?.requestPermissions(alert: true, sound: true) ??
      await _web?.requestNotificationsPermission();

  Future<bool?> _hasPermission() async {
    final android = _android;
    if (android != null) return android.areNotificationsEnabled();
    final ios = _ios;
    if (ios != null) return (await ios.checkPermissions())?.isEnabled;
    final web = _web;
    if (web != null) {
      return web.permissionStatus == WebNotificationPermission.granted;
    }
    return null;
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  WebFlutterLocalNotificationsPlugin? get _web => _plugin
      .resolvePlatformSpecificImplementation<
        WebFlutterLocalNotificationsPlugin
      >();

  @override
  Future<String?> launchPandalId() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details == null || !details.didNotificationLaunchApp) return null;
      final id = details.notificationResponse?.payload;
      return id == null || id.isEmpty ? null : id;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> show(NearbyPandal nearest, {required int othersNearby}) async {
    if (!_initialized) return;
    try {
      await _plugin.show(
        id: nearest.pandal.id.hashCode & 0x7fffffff,
        title: 'Pandal nearby: ${nearest.pandal.name}',
        body:
            '${formatDistance(nearest.meters)} away in ${nearest.pandal.area}'
            '${othersNearby > 0 ? ' · $othersNearby more within 3 km' : ''}',
        notificationDetails: _details,
        payload: nearest.pandal.id,
      );
    } catch (_) {
      // Plugin failure: there's no other way to show this alert.
    }
  }
}
