import 'package:durga_darshan/app.dart';
import 'package:durga_darshan/data/pandal_repository.dart';
import 'package:durga_darshan/models/pandal.dart';
import 'package:durga_darshan/models/parking_spot.dart';
import 'package:durga_darshan/services/app_storage.dart';
import 'package:durga_darshan/services/external_maps.dart';
import 'package:durga_darshan/services/location_source.dart';
import 'package:durga_darshan/state/parking_controller.dart';
import 'package:durga_darshan/widgets/map/previews.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'helpers/fake_location.dart';
import 'helpers/fake_tiles.dart';

// About 300 m north of the fake location's default fix.
const _pandal = Pandal(
  id: 'test-near',
  name: 'Test Near Pandal',
  area: 'Test Area',
  city: 'Ahmedabad',
  latitude: 23.0252,
  longitude: 72.5714,
  verificationStatus: VerificationStatus.verified,
);

void main() {
  final saturday = DateTime(2026, 10, 17, 19, 5);

  group('ParkingSpot', () {
    test('round-trips through its stored form', () {
      for (final spot in [
        ParkingSpot(latitude: 23.02, longitude: 72.57, savedAt: saturday),
        ParkingSpot(
          latitude: 23.02,
          longitude: 72.57,
          savedAt: saturday,
          accuracyMeters: 12.5,
          note: 'Basement 2',
        ),
      ]) {
        expect(ParkingSpot.tryDecode(spot.encode()), spot);
      }
    });

    test('unreadable records are ignored', () {
      for (final record in [
        null,
        'not json',
        '{"latitude": 91, "longitude": 72, "savedAt": "2026-10-17"}',
        '{"latitude": 23, "longitude": 72}',
        '{"latitude": 23, "longitude": 72, "savedAt": "2026-10-17", '
            '"note": 1}',
      ]) {
        expect(ParkingSpot.tryDecode(record), isNull, reason: record);
      }
    });
  });

  group('ParkingController', () {
    late FakeLocationSource location;
    late ParkingController parking;

    setUp(() {
      location = FakeLocationSource();
      parking = ParkingController(location: location, now: () => saturday);
    });

    tearDown(() => parking.dispose());

    test('saves where the device is now, asking for access first', () async {
      await parking.saveHere();
      expect(location.calls, ['requestAccess', 'currentFix']);
      expect(parking.status, ParkingStatus.idle);
      expect(
        parking.spot,
        ParkingSpot(
          latitude: 23.0225,
          longitude: 72.5714,
          savedAt: saturday,
          accuracyMeters: 8,
        ),
      );
    });

    test('a failed save keeps the earlier spot and says why', () async {
      await parking.saveHere();
      final saved = parking.spot;

      for (final (access, status) in [
        (LocationAccess.denied, ParkingStatus.locationDenied),
        (LocationAccess.deniedForever, ParkingStatus.locationDeniedForever),
        (LocationAccess.serviceDisabled, ParkingStatus.locationServiceOff),
      ]) {
        location.access = access;
        await parking.saveHere();
        expect(parking.status, status);
        expect(parking.spot, saved);
      }

      location
        ..access = LocationAccess.granted
        ..fix = null;
      await parking.saveHere();
      expect(parking.status, ParkingStatus.noFix);
      expect(parking.spot, saved);

      await parking.openSettings();
      expect(location.settingsOpened, [LocationAccess.deniedForever]);
    });

    test('notes are trimmed, and a blank one removes the note', () async {
      await parking.saveHere();
      parking.setNote('  Basement 2  ');
      expect(parking.spot?.note, 'Basement 2');
      parking.setNote('   ');
      expect(parking.spot?.note, isNull);
    });

    test('clearing can be undone', () async {
      await parking.saveHere();
      final saved = parking.spot!;
      parking.clear();
      expect(parking.spot, isNull);
      parking.restore(saved);
      expect(parking.spot, saved);
    });

    test('a map focus request is taken once, and only with a spot', () async {
      parking.requestFocus();
      expect(parking.takeFocusRequest(), isFalse);

      await parking.saveHere();
      parking.requestFocus();
      expect(parking.takeFocusRequest(), isTrue);
      expect(parking.takeFocusRequest(), isFalse);
    });
  });

  group('ExternalMaps.directionsTo', () {
    const spot = LatLng(23.0225, 72.5714);

    test('Android opens Google Maps walking directions, geo: fallback', () {
      final link = ExternalMaps.directionsTo(
        spot,
        label: 'My (parked) vehicle',
        platform: TargetPlatform.android,
        isWeb: false,
      );
      expect(link.primary.host, 'www.google.com');
      expect(link.primary.path, '/maps/dir/');
      expect(link.primary.queryParameters, {
        'api': '1',
        'destination': '23.022500,72.571400',
        'travelmode': 'walking',
      });
      expect(
        link.fallback.toString(),
        'geo:23.022500,72.571400?q=23.022500,72.571400(My%20parked%20vehicle)',
      );
    });

    test('iOS opens Apple Maps walking directions', () {
      final link = ExternalMaps.directionsTo(
        spot,
        label: 'My parked vehicle',
        platform: TargetPlatform.iOS,
        isWeb: false,
      );
      expect(link.primary.host, 'maps.apple.com');
      expect(link.primary.queryParameters, {
        'daddr': '23.022500,72.571400',
        'dirflg': 'w',
      });
      expect(link.fallback?.host, 'www.google.com');
    });

    test('the web opens Google Maps directions', () {
      final link = ExternalMaps.directionsTo(
        spot,
        label: 'My parked vehicle',
        isWeb: true,
      );
      expect(link.primary.host, 'www.google.com');
      expect(link.fallback, isNull);
    });
  });

  group('on screen', () {
    final realOpener = ExternalMaps.opener;
    late List<Uri> opened;

    setUp(() {
      opened = [];
      ExternalMaps.opener = (uri) async {
        opened.add(uri);
        return true;
      };
    });

    tearDown(() => ExternalMaps.opener = realOpener);

    Future<void> pumpApp(
      WidgetTester tester, {
      required AppStorage storage,
      FakeLocationSource? location,
    }) async {
      tester.view.physicalSize = const Size(400, 860);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        DurgaDarshanApp(
          repository: PandalRepository(const [_pandal]),
          storage: storage,
          mapTileProvider: FakeTileProvider(),
          locationSource: location ?? FakeLocationSource(),
          alertPresenter: FakeAlertPresenter(),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> tapVisible(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    String savedRecord({String? note, double accuracy = 8}) => ParkingSpot(
      latitude: 23.0225,
      longitude: 72.5714,
      savedAt: saturday,
      accuracyMeters: accuracy,
      note: note,
    ).encode();

    testWidgets('Save My Parking, then navigate back to the vehicle', (
      tester,
    ) async {
      final storage = MemoryStorage();
      await pumpApp(tester, storage: storage);
      expect(find.textContaining('Parked near a pandal?'), findsOneWidget);

      await tapVisible(tester, find.text('Save My Parking'));
      expect(find.textContaining('Saved '), findsOneWidget);
      expect(find.text('Near Test Near Pandal · 300 m'), findsOneWidget);
      final saved = ParkingSpot.tryDecode(storage.parkingSpotRecord)!;
      expect(saved.point, const LatLng(23.0225, 72.5714));

      await tapVisible(tester, find.text('Navigate to my vehicle'));
      expect(opened.single.host, 'www.google.com');
      expect(
        opened.single.queryParameters['destination'],
        '23.022500,72.571400',
      );
      expect(opened.single.queryParameters['travelmode'], 'walking');
    });

    testWidgets('updating the spot asks before replacing it', (tester) async {
      final location = FakeLocationSource();
      final storage = MemoryStorage(parkingSpotRecord: savedRecord());
      await pumpApp(tester, storage: storage, location: location);

      await tapVisible(tester, find.text('Update spot'));
      expect(find.text('Replace your parking spot?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(location.calls, isEmpty);

      location.fix = const LocationFix(LatLng(23.03, 72.58));
      await tapVisible(tester, find.text('Update spot'));
      await tester.tap(find.text('Replace'));
      await tester.pumpAndSettle();
      expect(
        ParkingSpot.tryDecode(storage.parkingSpotRecord)!.point,
        const LatLng(23.03, 72.58),
      );
    });

    testWidgets('a note can be added, and clearing can be undone', (
      tester,
    ) async {
      final storage = MemoryStorage(parkingSpotRecord: savedRecord());
      await pumpApp(tester, storage: storage);

      await tapVisible(tester, find.text('Add note'));
      await tester.enterText(find.byType(TextField).last, 'Basement 2');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Basement 2'), findsOneWidget);
      expect(
        ParkingSpot.tryDecode(storage.parkingSpotRecord)!.note,
        'Basement 2',
      );

      await tapVisible(tester, find.text('Clear'));
      expect(find.text('Save My Parking'), findsOneWidget);
      expect(storage.parkingSpotRecord, isNull);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('Basement 2'), findsOneWidget);
      expect(storage.parkingSpotRecord, isNotNull);
    });

    testWidgets('location problems are explained', (tester) async {
      final location = FakeLocationSource(access: LocationAccess.deniedForever);
      await pumpApp(tester, storage: MemoryStorage(), location: location);

      await tapVisible(tester, find.text('Save My Parking'));
      expect(find.textContaining('Location access is blocked'), findsOneWidget);
      await tapVisible(tester, find.text('Open settings'));
      expect(location.settingsOpened, [LocationAccess.deniedForever]);

      location
        ..access = LocationAccess.granted
        ..fix = null;
      await tapVisible(tester, find.text('Save My Parking'));
      expect(find.textContaining('Couldn’t get your location'), findsOneWidget);
    });

    testWidgets('a weak GPS fix is flagged as approximate', (tester) async {
      await pumpApp(
        tester,
        storage: MemoryStorage(parkingSpotRecord: savedRecord(accuracy: 120)),
      );
      expect(
        find.textContaining('Approximate spot (within about 120 m)'),
        findsOneWidget,
      );
    });

    testWidgets('Show on map opens the map on the vehicle', (tester) async {
      await pumpApp(
        tester,
        storage: MemoryStorage(parkingSpotRecord: savedRecord(note: 'Gate 3')),
      );

      await tapVisible(tester, find.text('Show on map'));
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byType(ParkingMapPreview), findsOneWidget);
      expect(find.text('Gate 3'), findsWidgets);
      final camera = MapCamera.of(
        tester.element(find.byType(MarkerLayer).first),
      );
      expect(camera.center.latitude, closeTo(23.0225, 1e-6));
      expect(camera.zoom, 17);

      await tester.tap(
        find.descendant(
          of: find.byType(ParkingMapPreview),
          matching: find.text('Navigate to my vehicle'),
        ),
      );
      await tester.pumpAndSettle();
      expect(opened.single.queryParameters['travelmode'], 'walking');

      await tester.tap(find.byTooltip('Close preview'));
      await tester.pumpAndSettle();
      expect(find.byType(ParkingMapPreview), findsNothing);
      await tester.tap(find.byTooltip('Show my parked vehicle'));
      await tester.pumpAndSettle();
      expect(find.byType(ParkingMapPreview), findsOneWidget);
    });

    testWidgets('Show on map also works once the map was opened before', (
      tester,
    ) async {
      await pumpApp(
        tester,
        storage: MemoryStorage(parkingSpotRecord: savedRecord()),
      );
      Future<void> openTab(String label) async {
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(label),
          ),
        );
        await tester.pumpAndSettle();
      }

      await openTab('Map');
      expect(find.byType(ParkingMapPreview), findsNothing);
      await openTab('Home');

      await tapVisible(tester, find.text('Show on map'));
      expect(find.byType(ParkingMapPreview), findsOneWidget);
      final camera = MapCamera.of(
        tester.element(find.byType(MarkerLayer).first),
      );
      expect(camera.center.latitude, closeTo(23.0225, 1e-6));
      expect(camera.zoom, 17);
    });

    testWidgets('the spot survives a restart', (tester) async {
      final storage = MemoryStorage();
      await pumpApp(tester, storage: storage);
      await tapVisible(tester, find.text('Save My Parking'));

      await tester.pumpWidget(const SizedBox());
      await pumpApp(tester, storage: storage);
      expect(find.text('Navigate to my vehicle'), findsOneWidget);
    });
  });
}
