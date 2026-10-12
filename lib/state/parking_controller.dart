import 'package:flutter/foundation.dart';

import '../models/parking_spot.dart';
import '../services/location_source.dart';

enum ParkingStatus {
  idle,
  locating,
  locationDenied,
  locationDeniedForever,
  locationServiceOff,

  /// Location is allowed but no fix came in time.
  noFix,
}

/// The saved parking spot: Save My Parking takes a fix of where the user is
/// now, and the spot stays until they replace or clear it. The app restores
/// it from, and saves it to, the device's storage.
class ParkingController extends ChangeNotifier {
  ParkingController({
    required this._location,
    ParkingSpot? initial,
    DateTime Function()? now,
  }) : _spot = initial,
       _now = now ?? DateTime.now;

  final LocationSource _location;
  final DateTime Function() _now;

  ParkingSpot? _spot;
  ParkingSpot? get spot => _spot;

  ParkingStatus _status = ParkingStatus.idle;
  ParkingStatus get status => _status;

  bool get isLocating => _status == ParkingStatus.locating;

  /// Saves where the device is now as the parking spot, replacing any
  /// earlier one, and asks for location access if needed. On failure the
  /// earlier spot is kept and [status] says why.
  Future<void> saveHere() async {
    if (isLocating) return;
    _set(ParkingStatus.locating);

    final access = await _location.requestAccess();
    switch (access) {
      case LocationAccess.granted:
        break;
      case LocationAccess.denied:
        return _set(ParkingStatus.locationDenied);
      case LocationAccess.deniedForever:
        return _set(ParkingStatus.locationDeniedForever);
      case LocationAccess.serviceDisabled:
        return _set(ParkingStatus.locationServiceOff);
    }

    final fix = await _location.currentFix();
    if (fix == null) return _set(ParkingStatus.noFix);
    _spot = ParkingSpot(
      latitude: fix.point.latitude,
      longitude: fix.point.longitude,
      savedAt: _now(),
      accuracyMeters: fix.accuracyMeters,
    );
    _set(ParkingStatus.idle);
  }

  /// Sets or, when blank, removes the spot's note.
  void setNote(String? note) {
    final spot = _spot;
    if (spot == null) return;
    final trimmed = note?.trim();
    final updated = spot.withNote(
      trimmed == null || trimmed.isEmpty ? null : trimmed,
    );
    if (updated == spot) return;
    _spot = updated;
    notifyListeners();
  }

  /// Forgets the spot, e.g. once the user is back at their vehicle.
  void clear() {
    if (_spot == null && _status == ParkingStatus.idle) return;
    _spot = null;
    _set(ParkingStatus.idle);
  }

  /// Puts back a spot, e.g. to undo [clear].
  void restore(ParkingSpot spot) {
    _spot = spot;
    _set(ParkingStatus.idle);
  }

  /// Opens the settings that would let a spot be saved.
  Future<void> openSettings() => _location.openSettings(
    _status == ParkingStatus.locationServiceOff
        ? LocationAccess.serviceDisabled
        : LocationAccess.deniedForever,
  );

  bool _focusRequested = false;

  /// Asks the map to show the spot when it is next built or shown.
  void requestFocus() {
    if (_spot == null) return;
    _focusRequested = true;
    notifyListeners();
  }

  /// Whether the map should show the spot now; answers true once per
  /// [requestFocus].
  bool takeFocusRequest() {
    final requested = _focusRequested && _spot != null;
    _focusRequested = false;
    return requested;
  }

  void _set(ParkingStatus status) {
    _status = status;
    notifyListeners();
  }
}
