import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/pandal.dart';
import '../models/proximity.dart';
import '../services/alert_presenter.dart';
import '../services/app_storage.dart';
import '../services/location_source.dart';

enum NearbyAlertsStatus {
  off,
  starting,
  active,
  notificationsDenied,
  locationDenied,
  locationDeniedForever,
  locationServiceOff,
}

/// Notifies the user when they come within 3 km of a pandal, while the app
/// is open or minimised.
///
/// Each pandal alerts at most once per day, across restarts, and alerts the
/// user left on come back on at the next launch (see [restore]).
class NearbyAlertsController extends ChangeNotifier {
  NearbyAlertsController({
    required this._pandals,
    required this._location,
    required this._presenter,
    AppStorage? storage,
    this.onOpenPandal,
    DateTime Function()? now,
  }) : _storage = storage,
       _now = now ?? DateTime.now {
    final today = _today();
    _alerted.addAll(
      (storage?.alertedPandals ?? const <String>[]).where(
        (key) => key.startsWith('$today|'),
      ),
    );
  }

  final List<Pandal> _pandals;
  final LocationSource _location;
  final AlertPresenter _presenter;
  final AppStorage? _storage;
  final DateTime Function() _now;

  /// Called when the user taps a notification.
  void Function(String pandalId)? onOpenPandal;

  StreamSubscription<LatLng>? _subscription;

  /// Pandals alerted today, as `<date>|<pandal id>`.
  final _alerted = <String>{};

  NearbyAlertsStatus _status = NearbyAlertsStatus.off;
  NearbyAlertsStatus get status => _status;

  bool get isOn =>
      _status == NearbyAlertsStatus.active ||
      _status == NearbyAlertsStatus.starting;

  LatLng? _position;

  /// Last known position while alerts are on.
  LatLng? get position => _position;

  /// Turns alerts on, asking for notification and location permission.
  Future<void> enable() => _start(askPermission: true);

  /// Turns alerts back on at launch if the user left them on. Asks for no
  /// permission: if one has been withdrawn, [status] says so instead.
  Future<void> restore() async {
    if (_storage?.nearbyAlertsOn ?? false) {
      await _start(askPermission: false);
    }
  }

  Future<void> _start({required bool askPermission}) async {
    if (isOn) return;
    _set(NearbyAlertsStatus.starting);

    // Alerts are notifications, so that permission comes first. Browsers
    // also only allow asking for it straight after a tap.
    final canNotify = await _presenter.prepare(
      onOpen: (id) => onOpenPandal?.call(id),
      askPermission: askPermission,
    );
    if (_status != NearbyAlertsStatus.starting) return; // turned off meanwhile
    if (!canNotify) {
      _set(NearbyAlertsStatus.notificationsDenied);
      return;
    }

    final access = askPermission
        ? await _location.requestAccess()
        : await _location.checkAccess();
    if (_status != NearbyAlertsStatus.starting) return;
    switch (access) {
      case LocationAccess.granted:
        _subscription = _location.positions().listen(
          _onPosition,
          onError: (_) => _stop(NearbyAlertsStatus.locationServiceOff),
        );
        _storage?.saveNearbyAlertsOn(true);
        _set(NearbyAlertsStatus.active);
      case LocationAccess.denied:
        _set(NearbyAlertsStatus.locationDenied);
      case LocationAccess.deniedForever:
        _set(NearbyAlertsStatus.locationDeniedForever);
      case LocationAccess.serviceDisabled:
        _set(NearbyAlertsStatus.locationServiceOff);
    }
  }

  /// Turns alerts off, and keeps them off at the next launch.
  void disable() {
    _storage?.saveNearbyAlertsOn(false);
    _stop(NearbyAlertsStatus.off);
  }

  /// Opens the settings that would let alerts work: the app's settings for
  /// blocked notifications or location, or the device's location settings.
  Future<void> openSettings() => _location.openSettings(
    _status == NearbyAlertsStatus.locationServiceOff
        ? LocationAccess.serviceDisabled
        : LocationAccess.deniedForever,
  );

  void _onPosition(LatLng position) {
    _position = position;
    final today = _today();
    final fresh = pandalsWithin(position, _pandals)
        .where((nearby) => !_alerted.contains('$today|${nearby.pandal.id}'))
        .toList();
    if (fresh.isNotEmpty) {
      _alerted
        ..removeWhere((key) => !key.startsWith('$today|'))
        ..addAll([for (final nearby in fresh) '$today|${nearby.pandal.id}']);
      _storage?.saveAlertedPandals(_alerted.toList());
      _presenter.show(fresh.first, othersNearby: fresh.length - 1);
    }
    notifyListeners();
  }

  String _today() {
    final now = _now();
    return '${now.year}-${now.month}-${now.day}';
  }

  void _stop(NearbyAlertsStatus status) {
    _subscription?.cancel();
    _subscription = null;
    _position = null;
    _set(status);
  }

  void _set(NearbyAlertsStatus status) {
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
