import 'package:durga_darshan/models/pandal.dart';
import 'package:durga_darshan/services/app_storage.dart';
import 'package:durga_darshan/services/location_source.dart';
import 'package:durga_darshan/state/nearby_alerts_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'helpers/fake_location.dart';

// Synthetic positions: 0.01° of latitude is about 1.11 km.
const _base = LatLng(23.0, 72.6);

LatLng _north(double km) =>
    LatLng(_base.latitude + km / 111.2, _base.longitude);

Pandal _pandal(String id, double kmNorth) {
  final point = _north(kmNorth);
  return Pandal(
    id: id,
    name: 'Test $id',
    area: 'Test Area',
    city: 'Ahmedabad',
    latitude: point.latitude,
    longitude: point.longitude,
    verificationStatus: VerificationStatus.verified,
  );
}

void main() {
  late FakeLocationSource location;
  late FakeAlertPresenter presenter;
  late List<String> calls;
  late DateTime now;
  late MemoryStorage storage;
  late NearbyAlertsController controller;

  /// A controller as the app creates it at launch, sharing [storage].
  NearbyAlertsController create() => NearbyAlertsController(
    pandals: [_pandal('a', 0), _pandal('b', 2), _pandal('far', 10)],
    location: location,
    presenter: presenter,
    storage: storage,
    now: () => now,
  );

  /// [create], disposed when the test ends.
  NearbyAlertsController launch() {
    final launched = create();
    addTearDown(launched.dispose);
    return launched;
  }

  setUp(() {
    calls = [];
    location = FakeLocationSource();
    presenter = FakeAlertPresenter(calls: calls);
    now = DateTime(2026, 10, 18, 18);
    storage = MemoryStorage();
    controller = launch();
    location.calls.clear();
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('starts off', () {
    expect(controller.status, NearbyAlertsStatus.off);
    expect(controller.isOn, isFalse);
    expect(location.isListened, isFalse);
  });

  test('enabling asks for notifications first, then location', () async {
    final log = <String>[];
    final ordered = NearbyAlertsController(
      pandals: const [],
      location: _LoggingLocation(log),
      presenter: FakeAlertPresenter(calls: log),
    );
    addTearDown(ordered.dispose);

    await ordered.enable();
    expect(log, ['prepare', 'requestAccess']);
    expect(ordered.status, NearbyAlertsStatus.active);
  });

  test('alerts once for pandals within 3 km', () async {
    await controller.enable();
    expect(controller.status, NearbyAlertsStatus.active);
    expect(location.isListened, isTrue);

    location.moveTo(_north(-1)); // a is 1 km away, b 3 km, far 11 km
    await settle();

    expect(controller.position, _north(-1));
    expect(presenter.shown, [(pandalId: 'a', others: 1)]);

    // Moving around nearby the same day doesn't repeat alerts.
    location.moveTo(_north(-0.5));
    await settle();
    expect(presenter.shown, hasLength(1));
  });

  test('stays quiet when nothing is within 3 km', () async {
    await controller.enable();
    location.moveTo(_north(-5));
    await settle();

    expect(presenter.shown, isEmpty);
    expect(controller.position, _north(-5));
  });

  test('a pandal reached later in the day still alerts', () async {
    await controller.enable();
    location.moveTo(_north(-2.5)); // only a is within 3 km
    await settle();
    location.moveTo(_north(4)); // now b (2 km) is new; a is 4 km away
    await settle();

    expect(presenter.shown.map((s) => s.pandalId), ['a', 'b']);
  });

  test('alerts again the next day', () async {
    await controller.enable();
    location.moveTo(_base);
    await settle();
    now = now.add(const Duration(days: 1));
    location.moveTo(_north(0.1));
    await settle();

    expect(presenter.shown.map((s) => s.pandalId), ['a', 'a']);
  });

  test('reports declined, blocked and switched-off location', () async {
    for (final (access, status) in [
      (LocationAccess.denied, NearbyAlertsStatus.locationDenied),
      (LocationAccess.deniedForever, NearbyAlertsStatus.locationDeniedForever),
      (LocationAccess.serviceDisabled, NearbyAlertsStatus.locationServiceOff),
    ]) {
      location.access = access;
      await controller.enable();
      expect(controller.status, status, reason: '$access');
      expect(controller.isOn, isFalse);
      expect(location.isListened, isFalse);
    }

    await controller.openSettings();
    expect(location.settingsOpened, [LocationAccess.serviceDisabled]);
  });

  test('turning off stops listening and clears the position', () async {
    await controller.enable();
    location.moveTo(_base);
    await settle();

    controller.disable();
    expect(controller.status, NearbyAlertsStatus.off);
    expect(location.isListened, isFalse);
    expect(controller.position, isNull);
  });

  test('losing location while on is reported', () async {
    await controller.enable();
    location.fail();
    await settle();

    expect(controller.status, NearbyAlertsStatus.locationServiceOff);
    expect(location.isListened, isFalse);
  });

  test('notification taps open pandals', () async {
    final opened = <String>[];
    controller.onOpenPandal = opened.add;
    await controller.enable();
    location.moveTo(_base);
    await settle();

    presenter.onOpen!('a');
    expect(opened, ['a']);
  });

  test('without notification permission alerts stay off', () async {
    presenter.canNotify = false;
    await controller.enable();

    expect(controller.status, NearbyAlertsStatus.notificationsDenied);
    expect(controller.isOn, isFalse);
    expect(location.calls, isEmpty, reason: 'location is not even asked');
    expect(location.isListened, isFalse);

    await controller.openSettings();
    expect(location.settingsOpened, [LocationAccess.deniedForever]);
  });

  group('across restarts', () {
    test('turning alerts on and off is remembered', () async {
      await controller.enable();
      expect(storage.nearbyAlertsOn, isTrue);

      controller.disable();
      expect(storage.nearbyAlertsOn, isFalse);
    });

    test('alerts left on come back on without asking', () async {
      await controller.enable();
      calls.clear();
      location.calls.clear();

      final relaunched = launch();
      await relaunched.restore();
      expect(relaunched.status, NearbyAlertsStatus.active);
      expect(calls, ['prepare (check only)']);
      expect(location.calls, ['checkAccess']);
      expect(location.isListened, isTrue);
    });

    test('alerts left off stay off', () async {
      await controller.restore();
      expect(controller.status, NearbyAlertsStatus.off);
      expect(calls, isEmpty);
      expect(location.calls, isEmpty);
    });

    test('a withdrawn permission is reported, not asked for', () async {
      storage = MemoryStorage(nearbyAlertsOn: true);
      location.access = LocationAccess.denied;
      final relaunched = launch();
      await relaunched.restore();
      expect(relaunched.status, NearbyAlertsStatus.locationDenied);
      expect(location.calls, ['checkAccess']);

      presenter.canNotify = false;
      final again = launch();
      await again.restore();
      expect(again.status, NearbyAlertsStatus.notificationsDenied);
      expect(calls.last, 'prepare (check only)');
      // Still wanted: alerts come back once the permission is restored.
      expect(storage.nearbyAlertsOn, isTrue);
    });

    test('a pandal alerted earlier today stays quiet', () async {
      final first = create();
      await first.enable();
      location.moveTo(_north(-2.5)); // only a is within 3 km
      await settle();
      expect(presenter.shown.map((s) => s.pandalId), ['a']);

      first.dispose(); // the app is closed
      final relaunched = launch();
      await relaunched.restore();
      location.moveTo(_north(-1)); // a again, and now b
      await settle();
      expect(presenter.shown.map((s) => s.pandalId), ['a', 'b']);
    });

    test('alerts from an earlier day are forgotten', () async {
      storage = MemoryStorage(
        nearbyAlertsOn: true,
        alertedPandals: const ['2026-10-17|a'],
      );
      final relaunched = launch();
      await relaunched.restore();
      location.moveTo(_base);
      await settle();
      expect(presenter.shown, [(pandalId: 'a', others: 1)]); // b, 2 km
      expect(storage.alertedPandals, ['2026-10-18|a', '2026-10-18|b']);
    });
  });
}

class _LoggingLocation extends FakeLocationSource {
  _LoggingLocation(this.log);

  final List<String> log;

  @override
  Future<LocationAccess> requestAccess() {
    log.add('requestAccess');
    return super.requestAccess();
  }
}
