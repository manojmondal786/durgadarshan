import 'dart:async';

import 'package:durga_darshan/models/proximity.dart';
import 'package:durga_darshan/services/alert_presenter.dart';
import 'package:durga_darshan/services/location_source.dart';
import 'package:latlong2/latlong.dart';

/// Location under test control: no platform plugin is touched.
class FakeLocationSource implements LocationSource {
  FakeLocationSource({
    this.access = LocationAccess.granted,
    this.fix = const LocationFix(LatLng(23.0225, 72.5714), accuracyMeters: 8),
  });

  LocationAccess access;

  /// What [currentFix] returns; null as if no fix came in time.
  LocationFix? fix;
  final _positions = StreamController<LatLng>.broadcast();
  final settingsOpened = <LocationAccess>[];
  final calls = <String>[];

  bool get isListened => _positions.hasListener;

  void moveTo(LatLng position) => _positions.add(position);

  void fail() => _positions.addError(StateError('Location turned off'));

  @override
  Future<LocationAccess> requestAccess() async {
    calls.add('requestAccess');
    return access;
  }

  @override
  Future<LocationAccess> checkAccess() async {
    calls.add('checkAccess');
    return access;
  }

  @override
  Stream<LatLng> positions() => _positions.stream;

  @override
  Future<LocationFix?> currentFix() async {
    calls.add('currentFix');
    return fix;
  }

  @override
  Future<void> openSettings(LocationAccess access) async =>
      settingsOpened.add(access);
}

/// Records alerts instead of showing system notifications.
class FakeAlertPresenter implements AlertPresenter {
  FakeAlertPresenter({this.calls, this.canNotify = true, this.launchedFrom});

  /// Shared call log, to check ordering against the location source.
  final List<String>? calls;

  /// Whether notification permission is (or will be) granted.
  bool canNotify;

  /// The pandal whose notification "launched" the app.
  String? launchedFrom;

  final shown = <({String pandalId, int others})>[];
  void Function(String pandalId)? onOpen;

  @override
  Future<bool> prepare({
    required void Function(String pandalId) onOpen,
    bool askPermission = true,
  }) async {
    calls?.add(askPermission ? 'prepare' : 'prepare (check only)');
    this.onOpen = onOpen;
    return canNotify;
  }

  @override
  Future<String?> launchPandalId() async => launchedFrom;

  @override
  Future<void> show(NearbyPandal nearest, {required int othersNearby}) async =>
      shown.add((pandalId: nearest.pandal.id, others: othersNearby));
}
