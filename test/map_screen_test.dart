import 'package:durga_darshan/app.dart';
import 'package:durga_darshan/data/map_config.dart';
import 'package:durga_darshan/data/pandal_repository.dart';
import 'package:durga_darshan/services/app_storage.dart';
import 'package:durga_darshan/models/pandal.dart';
import 'package:durga_darshan/services/external_maps.dart';
import 'package:durga_darshan/state/app_scope.dart';
import 'package:durga_darshan/widgets/map/pins.dart';
import 'package:durga_darshan/widgets/map/previews.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'helpers/fake_location.dart';
import 'helpers/fake_tiles.dart';
import 'helpers/test_data.dart';

void main() {
  // The 25 pandals with no map locations, as transcribed from the poster.
  late PandalRepository poster;
  final realOpener = ExternalMaps.opener;
  late List<Uri> opened;

  // Synthetic fixtures: one pin-worthy pandal and two that must not be pinned
  // even though they have coordinates.
  final fixtures = PandalRepository(const [
    Pandal(
      id: 'test-verified',
      name: 'Test Verified Pandal',
      area: 'Test Area',
      city: 'Ahmedabad',
      latitude: 23.0225,
      longitude: 72.5714,
      verificationStatus: VerificationStatus.verified,
    ),
    Pandal(
      id: 'test-unverified',
      name: 'Test Unverified Pandal',
      area: 'Test Area',
      city: 'Ahmedabad',
      latitude: 23.05,
      longitude: 72.55,
    ),
    Pandal(
      id: 'test-conflicting',
      name: 'Test Conflicting Pandal',
      area: 'Test Area',
      city: 'Ahmedabad',
      latitude: 23.0,
      longitude: 72.6,
      verificationStatus: VerificationStatus.conflicting,
    ),
  ]);

  setUpAll(() {
    poster = posterSnapshot();
  });

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
    PandalRepository? repository,
    required FakeTileProvider tiles,
    FakeLocationSource? location,
  }) async {
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      DurgaDarshanApp(
        storage: MemoryStorage(),
        repository: repository ?? poster,
        mapTileProvider: tiles,
        locationSource: location ?? FakeLocationSource(),
        alertPresenter: FakeAlertPresenter(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openMapTab(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Map'),
      ),
    );
    await tester.pumpAndSettle();
  }

  MapCamera camera(WidgetTester tester) =>
      MapCamera.of(tester.element(find.byType(MarkerLayer).first));

  testWidgets('the map is only built once the Map tab is opened', (
    tester,
  ) async {
    final tiles = FakeTileProvider();
    await pumpApp(tester, tiles: tiles);

    expect(find.byType(FlutterMap, skipOffstage: false), findsNothing);
    expect(tiles.requests, 0);

    await openMapTab(tester);
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(tiles.requests, greaterThan(0));
  });

  testWidgets('without pins it starts on Ahmedabad', (tester) async {
    await pumpApp(tester, tiles: FakeTileProvider());
    await openMapTab(tester);

    expect(camera(tester).center, MapConfig.ahmedabadCenter);
    expect(camera(tester).zoom, MapConfig.initialZoom);
    expect(find.byType(PandalPin), findsNothing);
    expect(find.text('Ahmedabad and nearby areas'), findsOneWidget);
    expect(find.textContaining('verif'), findsNothing);
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
  });

  testWidgets('zoom, pan and reset controls move the camera', (tester) async {
    await pumpApp(tester, tiles: FakeTileProvider());
    await openMapTab(tester);

    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pumpAndSettle();
    expect(camera(tester).zoom, MapConfig.initialZoom + 1);

    await tester.tap(find.byTooltip('Zoom out'));
    await tester.tap(find.byTooltip('Zoom out'));
    await tester.pumpAndSettle();
    expect(camera(tester).zoom, MapConfig.initialZoom - 1);

    await tester.dragFrom(
      tester.getCenter(find.byType(FlutterMap)),
      const Offset(-150, 90),
    );
    await tester.pumpAndSettle();
    expect(camera(tester).center, isNot(MapConfig.ahmedabadCenter));

    await tester.tap(find.byTooltip('Reset map view'));
    await tester.pumpAndSettle();
    expect(camera(tester).center, MapConfig.ahmedabadCenter);
    expect(camera(tester).zoom, MapConfig.initialZoom);
  });

  testWidgets('attribution links to the OpenStreetMap copyright page', (
    tester,
  ) async {
    await pumpApp(tester, tiles: FakeTileProvider());
    await openMapTab(tester);

    await tester.tap(find.text('© OpenStreetMap contributors'));
    await tester.pumpAndSettle();
    expect(opened, [Uri.parse(MapConfig.osmCopyrightUrl)]);
  });

  testWidgets('tile failures show a retry banner instead of breaking', (
    tester,
  ) async {
    final tiles = FakeTileProvider(online: false);
    await pumpApp(tester, tiles: tiles);
    await openMapTab(tester);

    expect(find.textContaining('Map tiles couldn’t load'), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);

    tiles.online = true;
    final before = tiles.requests;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Map tiles couldn’t load'), findsNothing);
    expect(tiles.requests, greaterThan(before));
  });

  testWidgets('only verified pandals get pins, with preview and actions', (
    tester,
  ) async {
    await pumpApp(tester, repository: fixtures, tiles: FakeTileProvider());
    await openMapTab(tester);

    expect(find.byType(PandalPin), findsOneWidget);
    expect(find.text('1 pandal on the map'), findsOneWidget);

    await tester.tap(find.byType(PandalPin));
    await tester.pumpAndSettle();
    expect(find.byType(PandalMapPreview), findsOneWidget);
    expect(find.text('Test Verified Pandal'), findsOneWidget);
    expect(find.text('Test Area'), findsOneWidget);
    expect(find.textContaining('VERIFIED'), findsNothing);

    await tester.tap(find.text('Open in Maps'));
    await tester.pumpAndSettle();
    expect(opened.single.scheme, 'geo');
    expect(opened.single.path, '23.022500,72.571400');

    await tester.tap(find.text('View details'));
    await tester.pumpAndSettle();
    expect(find.text('Visiting Hours'), findsOneWidget);
    expect(find.text('Search in Maps'), findsNothing);

    await tester.ensureVisible(find.text('Open in Maps'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open in Maps'));
    await tester.pumpAndSettle();
    expect(opened, hasLength(2));

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close preview'));
    await tester.pumpAndSettle();
    expect(find.byType(PandalMapPreview), findsNothing);
  });

  testWidgets('an area-level pin says so and searches for the venue', (
    tester,
  ) async {
    final areaPin = PandalRepository(const [
      Pandal(
        id: 'test-area-pin',
        name: 'Test Area Pandal',
        area: 'Test Area',
        city: 'Ahmedabad',
        address: 'Near Test Garden, Test Area.',
        latitude: 23.0225,
        longitude: 72.5714,
        verificationStatus: VerificationStatus.verified,
        pinPrecision: PinPrecision.area,
        venueNeedsChecking: true,
      ),
    ]);
    await pumpApp(tester, repository: areaPin, tiles: FakeTileProvider());
    await openMapTab(tester);

    await tester.tap(find.byType(PandalPin));
    await tester.pumpAndSettle();
    expect(
      find.text('Pin shows the area, not the exact venue'),
      findsOneWidget,
    );

    await tester.tap(find.text('Open in Maps'));
    await tester.pumpAndSettle();
    expect(opened.single.scheme, 'geo');
    expect(opened.single.path, '23.022500,72.571400');
    expect(
      opened.single.queryParameters['q'],
      'Test Area Pandal, Near Test Garden, Test Area, Ahmedabad',
    );

    await tester.tap(find.text('View details'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Venue as listed by the organisers. Please check before you '
        'travel.\nMap pin shows the area. Use the address to find the '
        'venue.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('the map opens framed around every pin', (tester) async {
    // Synthetic pins roughly 40 km apart, like Gandhinagar and Bavla.
    const north = LatLng(23.24, 72.65);
    const southWest = LatLng(22.83, 72.37);
    await pumpApp(
      tester,
      repository: PandalRepository(const [
        Pandal(
          id: 'test-north',
          name: 'Test North',
          area: 'North',
          city: 'Ahmedabad',
          latitude: 23.24,
          longitude: 72.65,
          verificationStatus: VerificationStatus.verified,
        ),
        Pandal(
          id: 'test-south-west',
          name: 'Test South West',
          area: 'South West',
          city: 'Ahmedabad',
          latitude: 22.83,
          longitude: 72.37,
          verificationStatus: VerificationStatus.verified,
        ),
      ]),
      tiles: FakeTileProvider(),
    );
    await openMapTab(tester);

    bool framed() =>
        camera(tester).visibleBounds.contains(north) &&
        camera(tester).visibleBounds.contains(southWest);
    expect(find.byType(PandalPin), findsNWidgets(2));
    expect(framed(), isTrue);

    await tester.tap(find.byTooltip('Zoom in'));
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pumpAndSettle();
    expect(framed(), isFalse);

    await tester.tap(find.byTooltip('Reset map view'));
    await tester.pumpAndSettle();
    expect(framed(), isTrue);
  });

  testWidgets('pandals at the same spot share one pin', (tester) async {
    await pumpApp(
      tester,
      repository: PandalRepository(const [
        Pandal(
          id: 'test-first',
          name: 'Test First Pandal',
          area: 'Test Area',
          city: 'Ahmedabad',
          latitude: 23.0225,
          longitude: 72.5714,
          verificationStatus: VerificationStatus.verified,
        ),
        Pandal(
          id: 'test-second',
          name: 'Test Second Pandal',
          area: 'Test Area',
          city: 'Ahmedabad',
          latitude: 23.0225,
          longitude: 72.5714,
          verificationStatus: VerificationStatus.verified,
        ),
      ]),
      tiles: FakeTileProvider(),
    );
    await openMapTab(tester);

    expect(find.byType(PandalPin), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('2 pandals on the map'), findsOneWidget);

    await tester.tap(find.byType(PandalPin));
    await tester.pumpAndSettle();
    expect(find.byType(PandalGroupPreview), findsOneWidget);
    expect(find.text('2 pandals here'), findsOneWidget);

    await tester.tap(find.text('Test Second Pandal'));
    await tester.pumpAndSettle();
    expect(find.text('Test Second Pandal'), findsWidgets);
    expect(find.text('Visiting Hours'), findsOneWidget);
  });

  testWidgets('shows your location while nearby alerts are on', (tester) async {
    final location = FakeLocationSource();
    await pumpApp(
      tester,
      repository: fixtures,
      tiles: FakeTileProvider(),
      location: location,
    );
    await openMapTab(tester);
    expect(find.byType(UserLocationDot), findsNothing);

    await AppScope.of(tester.element(find.byType(FlutterMap))).nearbyAlerts
        .enable();
    location.moveTo(const LatLng(23.03, 72.58));
    await tester.pumpAndSettle();
    expect(find.byType(UserLocationDot), findsOneWidget);
  });
}
