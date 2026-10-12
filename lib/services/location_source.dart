import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_colors.dart';

enum LocationAccess { granted, denied, deniedForever, serviceDisabled }

/// One position reading and how accurate the device says it is.
@immutable
class LocationFix {
  const LocationFix(this.point, {this.accuracyMeters});

  final LatLng point;
  final double? accuracyMeters;
}

/// The device's position, behind an interface so tests can fake it.
abstract interface class LocationSource {
  /// Asks for "while using the app" access if needed. Never asks for
  /// "all the time" (background) access.
  Future<LocationAccess> requestAccess();

  /// The current access, without asking for anything.
  Future<LocationAccess> checkAccess();

  /// Position updates while listened to, including while the app is
  /// minimised.
  Stream<LatLng> positions();

  /// One precise fix of where the device is now, e.g. to save a parking
  /// spot; null if none comes in time.
  Future<LocationFix?> currentFix();

  /// Opens the app's settings page (its location and notification
  /// permissions), or the device's location settings when location is
  /// switched off.
  Future<void> openSettings(LocationAccess access);
}

class DeviceLocationSource implements LocationSource {
  const DeviceLocationSource();

  @override
  Future<LocationAccess> requestAccess() => _access(request: true);

  @override
  Future<LocationAccess> checkAccess() => _access(request: false);

  Future<LocationAccess> _access({required bool request}) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAccess.serviceDisabled;
    }
    var permission = await Geolocator.checkPermission();
    if (request && permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return switch (permission) {
      LocationPermission.whileInUse ||
      LocationPermission.always => LocationAccess.granted,
      LocationPermission.deniedForever => LocationAccess.deniedForever,
      LocationPermission.denied ||
      LocationPermission.unableToDetermine => LocationAccess.denied,
    };
  }

  @override
  Future<LocationFix?> currentFix() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        // A parking spot needs GPS precision, unlike the alerts.
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return LocationFix(
        LatLng(position.latitude, position.longitude),
        accuracyMeters: position.accuracy > 0 ? position.accuracy : null,
      );
    } catch (_) {
      // Timed out, or location turned off meanwhile.
      return null;
    }
  }

  @override
  Stream<LatLng> positions() =>
      Geolocator.getPositionStream(locationSettings: _settings())
          .map((position) => LatLng(position.latitude, position.longitude));

  /// A 3 km radius doesn't need GPS precision: medium accuracy and a 150 m
  /// step save battery. Updates carry on while the app is minimised, which
  /// "while using the app" access allows once they started in the
  /// foreground: Android runs them in a foreground service with its own
  /// ongoing notification, and iOS shows its background location indicator.
  /// They stop when the app is closed.
  static LocationSettings _settings() {
    const accuracy = LocationAccuracy.medium;
    const distanceFilter = 150;
    if (kIsWeb) {
      return const LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter,
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: 'Watching for nearby pandals',
            notificationText:
                'You’ll be notified within 3 km of a pandal. Turn alerts '
                'off in the app.',
            notificationChannelName: 'Nearby pandal watch',
            notificationIcon: AndroidResource(name: 'ic_stat_pandal'),
            setOngoing: true,
            color: AppColors.maroon,
          ),
        );
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return AppleSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter,
          allowBackgroundLocationUpdates: true,
          showBackgroundLocationIndicator: true,
          // Once paused, iOS only resumes updates in the foreground.
          pauseLocationUpdatesAutomatically: false,
        );
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return const LocationSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter,
        );
    }
  }

  @override
  Future<void> openSettings(LocationAccess access) async {
    if (access == LocationAccess.serviceDisabled) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }
}
