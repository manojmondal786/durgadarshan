import 'package:durga_darshan/app.dart';
import 'package:durga_darshan/data/pandal_repository.dart';
import 'package:durga_darshan/models/pandal.dart';
import 'package:durga_darshan/services/app_storage.dart';
import 'package:durga_darshan/services/external_maps.dart';
import 'package:durga_darshan/services/location_source.dart';
import 'package:durga_darshan/theme/app_images.dart';
import 'package:durga_darshan/theme/app_motion.dart';
import 'package:durga_darshan/widgets/about_pandal_card.dart';
import 'package:durga_darshan/widgets/address_search_sheet.dart';
import 'package:durga_darshan/widgets/map/pins.dart';
import 'package:durga_darshan/widgets/pandal_cards.dart';
import 'package:durga_darshan/widgets/visiting_hours_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'helpers/fake_location.dart';
import 'helpers/fake_tiles.dart';
import 'helpers/test_data.dart';

final _anyVerificationWording = RegExp(
  r'verif|need(s)? check|unclear',
  caseSensitive: false,
);

// Synthetic pinned pandal for alert tests.
const _pinned = Pandal(
  id: 'test-pinned',
  name: 'Test Pinned Pandal',
  area: 'Test Area',
  city: 'Ahmedabad',
  address: 'Test address',
  latitude: 23.0225,
  longitude: 72.5714,
  verificationStatus: VerificationStatus.verified,
);

void main() {
  late PandalRepository repository;
  final realOpener = ExternalMaps.opener;
  late List<Uri> opened;

  setUpAll(() {
    // Independent of which locations have been verified so far.
    repository = posterSnapshot();
  });

  // Record instead of launching anything outside the test.
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
    Size size = const Size(400, 860),
    bool loadFromAssets = false,
    PandalRepository? data,
    FakeLocationSource? location,
    FakeAlertPresenter? presenter,
    AppStorage? storage,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      DurgaDarshanApp(
        repository: loadFromAssets ? null : data ?? repository,
        storage: storage ?? MemoryStorage(),
        mapTileProvider: FakeTileProvider(),
        locationSource: location ?? FakeLocationSource(),
        alertPresenter: presenter ?? FakeAlertPresenter(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Area chips scroll horizontally and are built lazily, so rewind the row
  // and scroll forward until the chip is on screen before tapping it.
  Future<void> tapChip(WidgetTester tester, String label) async {
    final chipRow = find.byType(ListView);
    final chip = find.descendant(of: chipRow, matching: find.text(label));
    await tester.drag(chipRow, const Offset(4000, 0));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      chip,
      150,
      scrollable: find
          .descendant(of: chipRow, matching: find.byType(Scrollable))
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> openDetailsFromList(WidgetTester tester, String query) async {
    await openTab(tester, 'Pandals');
    await tester.enterText(find.byType(TextField), query);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PandalListCard).first);
    await tester.pumpAndSettle();
  }

  testWidgets('shows the splash, then the bundled pandal list on Home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      DurgaDarshanApp(
        storage: MemoryStorage(),
        mapTileProvider: FakeTileProvider(),
        locationSource: FakeLocationSource(),
        alertPresenter: FakeAlertPresenter(),
      ),
    );

    // The splash animates in and stays up for a moment, even though the
    // list loads at once.
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('Durga\nDarshan'), findsOneWidget);
    expect(find.text('শুভ শারদীয়া'), findsOneWidget);
    expect(find.text('Explore Pandals'), findsNothing);

    await tester.pump(AppMotion.splashMinimum);
    await tester.pumpAndSettle();
    expect(find.text('Durga\nDarshan'), findsNothing);

    expect(find.text('Shubho Sharodiya'), findsOneWidget);
    expect(find.text('Explore Pandals'), findsOneWidget);
    expect(
      find.text('Airports Authority of India Community Hall'),
      findsOneWidget,
    );
    expect(find.textContaining(_anyVerificationWording), findsNothing);
    expect(
      find.text('Nearby pandal alerts', skipOffstage: false),
      findsOneWidget,
    );

    // Every bundled pandal is pinned.
    final explore = find.text('Explore on Map', skipOffstage: false);
    expect(
      find.text('Find all pandal locations', skipOffstage: false),
      findsOneWidget,
    );
    await tester.ensureVisible(explore);
    await tester.pumpAndSettle();
    await tester.tap(explore);
    await tester.pumpAndSettle();
    expect(find.text('Pandal Map'), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);
  });

  testWidgets('searching from Home opens the filtered list', (tester) async {
    await pumpApp(tester);

    await tester.enterText(find.byType(TextField), 'kalibari');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('All Pandals'), findsOneWidget);
    expect(find.text('2 pandals'), findsOneWidget);
    expect(
      find.text('Naroda kalibari, All Gujarat Resurgent Trust'),
      findsOneWidget,
    );
    expect(find.text('Ahmedabad Kalibari pujo'), findsOneWidget);
  });

  testWidgets('list filters by area and favourites', (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'Pandals');
    expect(find.text('25 pandals'), findsOneWidget);

    await tapChip(tester, 'Ghodasar');
    expect(find.text('2 pandals'), findsOneWidget);
    expect(find.text('Vaibhav hall'), findsOneWidget);
    expect(find.text('Shakti dwar charitable trust'), findsOneWidget);

    await tester.tap(find.text('Clear filters').first);
    await tester.pumpAndSettle();
    expect(find.text('25 pandals'), findsOneWidget);

    await tapChip(tester, 'Favourites');
    expect(find.text('No favourites yet'), findsOneWidget);

    await tapChip(tester, 'Favourites');
    await tester.tap(find.byTooltip('Add to favourites').first);
    await tester.pumpAndSettle();
    await tapChip(tester, 'Favourites');
    expect(find.text('1 pandal'), findsOneWidget);
    expect(
      find.text('Airports Authority of India Community Hall'),
      findsOneWidget,
    );
  });

  testWidgets(
    'details without a pin show tentative hours and search the address',
    (tester) async {
      await pumpApp(tester);
      await openDetailsFromList(tester, 'vaibhav');

      expect(find.text('Ghodasar brst cross road, Ghodasar.'), findsOneWidget);
      expect(find.text(VisitingHoursCard.estimatedTag), findsOneWidget);
      expect(
        find.text('Until 12:00 AM (Midnight) — Tentative', findRichText: true),
        findsOneWidget,
      );
      expect(find.text(VisitingHoursCard.cutoffDisclaimer), findsOneWidget);
      expect(find.text('Not announced yet'), findsNothing);
      expect(find.text(AboutPandalCard.title), findsOneWidget);
      expect(
        find.textContaining('Vaibhav Hall, by the Ghodasar'),
        findsOneWidget,
      );
      expect(find.textContaining('will be added'), findsNothing);
      expect(find.text('Representative image'), findsOneWidget);
      // Poster caution notes are kept in the data but never shown.
      expect(find.text('Notes from the list'), findsNothing);
      expect(find.textContaining('BRTS'), findsNothing);
      expect(find.textContaining(_anyVerificationWording), findsNothing);

      await tapVisible(tester, find.text('Add to Favourites'));
      expect(find.text('Saved to Favourites'), findsOneWidget);

      expect(find.text('Open in Maps'), findsNothing);
      await tapVisible(tester, find.text('Search in Maps'));
      expect(find.byType(AddressSearchSheet), findsOneWidget);
      expect(
        find.textContaining('Check that the result matches'),
        findsOneWidget,
      );
      expect(find.textContaining(_anyVerificationWording), findsNothing);
      expect(
        find.text(
          'Vaibhav hall, Ghodasar brst cross road, Ghodasar, Ahmedabad',
        ),
        findsOneWidget,
      );
      expect(opened, isEmpty, reason: 'nothing opens until a search is chosen');

      await tester.tap(
        find.descendant(
          of: find.byType(AddressSearchSheet),
          matching: find.byIcon(Icons.travel_explore_rounded),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AddressSearchSheet), findsNothing);
      expect(opened.single.scheme, 'geo');
      expect(opened.single.path, '0,0');
      expect(
        opened.single.queryParameters['q'],
        'Vaibhav hall, Ghodasar brst cross road, Ghodasar, Ahmedabad',
      );

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('All Pandals'), findsOneWidget);
      expect(find.byTooltip('Remove from favourites'), findsOneWidget);
    },
  );

  testWidgets('details show printed timings and visible notes', (tester) async {
    await pumpApp(tester);
    await openDetailsFromList(tester, 'chatterjee');

    expect(find.text(VisitingHoursCard.posterTag), findsOneWidget);
    expect(find.text('Morning visiting'), findsOneWidget);
    expect(find.text('9:00 AM – 12:30 PM'), findsOneWidget);
    expect(find.text('Evening visiting'), findsOneWidget);
    expect(find.text('6:00 PM – 9:00 PM'), findsOneWidget);
    expect(find.text('Evening Aarti'), findsOneWidget);
    expect(find.text('8:00 PM'), findsOneWidget);
    expect(
      find.text('As printed on the 2026 Ahmedabad Durga Puja list.'),
      findsOneWidget,
    );
    // The poster's hours are never replaced by the planning cutoff.
    expect(find.text(VisitingHoursCard.estimatedTag), findsNothing);
    expect(find.textContaining('Midnight', findRichText: true), findsNothing);

    expect(find.textContaining('private home'), findsOneWidget);
    expect(find.text('Notes from the list'), findsOneWidget);
    expect(find.textContaining('BARIR PUJO'), findsOneWidget);
  });

  testWidgets('the bundled data shows no verification tags or caution notes', (
    tester,
  ) async {
    await pumpApp(tester, data: loadBundledPandals());
    await openTab(tester, 'Pandals');
    expect(find.textContaining(_anyVerificationWording), findsNothing);

    await tester.enterText(find.byType(TextField), 'savvy');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PandalListCard).first);
    await tester.pumpAndSettle();

    expect(find.text('Savvy Swaraj, Gota, Ahmedabad.'), findsOneWidget);
    expect(find.textContaining('Jagatpur'), findsNothing);
    expect(find.text('Notes from the list'), findsNothing);
    expect(find.textContaining(_anyVerificationWording), findsNothing);
  });

  testWidgets('an address listing two venues offers a search for each', (
    tester,
  ) async {
    await pumpApp(
      tester,
      data: PandalRepository(const [
        Pandal(
          id: 'test-two-venues',
          name: 'Test Two Venues',
          area: 'Test Area',
          city: 'Ahmedabad',
          address: 'First Hall, Test Area / Second Ground, Other Area',
        ),
      ]),
    );
    await openDetailsFromList(tester, 'test');

    await tapVisible(tester, find.text('Search in Maps'));
    expect(find.text('VENUE 1 OF 2'), findsOneWidget);
    expect(find.text('VENUE 2 OF 2'), findsOneWidget);
    expect(find.textContaining('2 possible venues'), findsOneWidget);

    final secondVenue = find
        .descendant(
          of: find.byType(AddressSearchSheet),
          matching: find.byIcon(Icons.travel_explore_rounded),
        )
        .last;
    await tester.ensureVisible(secondVenue);
    await tester.pumpAndSettle();
    await tester.tap(secondVenue);
    await tester.pumpAndSettle();
    expect(opened.single.queryParameters['q'], contains('Second Ground'));
  });

  testWidgets('a pandal without an address or pin explains why', (
    tester,
  ) async {
    await pumpApp(
      tester,
      data: PandalRepository(const [
        Pandal(
          id: 'test-no-address',
          name: 'Test Pandal',
          area: 'Test Area',
          city: 'Ahmedabad',
        ),
      ]),
    );
    await openDetailsFromList(tester, 'test');

    expect(find.text('Search in Maps'), findsNothing);
    await tester.ensureVisible(find.text('Open in Maps'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open in Maps'));
    await tester.pump();
    expect(find.textContaining('no address or map location'), findsOneWidget);
    expect(opened, isEmpty);
  });

  Future<void> tapAlertsSwitch(WidgetTester tester) async {
    final toggle = find.byType(Switch, skipOffstage: false);
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
  }

  testWidgets('nearby alerts turn on from Home and notify', (tester) async {
    final location = FakeLocationSource();
    final presenter = FakeAlertPresenter();
    await pumpApp(
      tester,
      data: PandalRepository(const [_pinned]),
      location: location,
      presenter: presenter,
    );

    expect(location.isListened, isFalse, reason: 'off until switched on');
    await tapAlertsSwitch(tester);
    expect(find.textContaining('On. You’ll be notified'), findsOneWidget);
    expect(location.isListened, isTrue);

    location.moveTo(const LatLng(23.0300, 72.5714)); // about 840 m away
    await tester.pumpAndSettle();
    expect(presenter.shown, [(pandalId: 'test-pinned', others: 0)]);
    expect(find.text('PANDAL NEARBY'), findsNothing, reason: 'no banner');

    await tapAlertsSwitch(tester);
    expect(location.isListened, isFalse);
  });

  testWidgets('nearby alerts keep running while the app is minimised', (
    tester,
  ) async {
    final location = FakeLocationSource();
    final presenter = FakeAlertPresenter();
    await pumpApp(
      tester,
      data: PandalRepository(const [_pinned]),
      location: location,
      presenter: presenter,
    );
    await tapAlertsSwitch(tester);

    void moveTo(List<AppLifecycleState> states) {
      for (final state in states) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
    }

    moveTo([
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]);
    expect(location.isListened, isTrue);
    location.moveTo(const LatLng(23.0300, 72.5714));
    await tester.pump();
    expect(presenter.shown, hasLength(1));

    moveTo([
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]);
    expect(location.isListened, isTrue);
  });

  testWidgets('tapping a nearby notification opens the pandal', (tester) async {
    final presenter = FakeAlertPresenter();
    await pumpApp(
      tester,
      data: PandalRepository(const [_pinned]),
      presenter: presenter,
    );
    await tapAlertsSwitch(tester);

    presenter.onOpen!('test-pinned');
    await tester.pumpAndSettle();
    expect(find.text('Visiting Hours'), findsOneWidget);
  });

  testWidgets('blocked location access points to Settings', (tester) async {
    final location = FakeLocationSource(access: LocationAccess.deniedForever);
    await pumpApp(
      tester,
      data: PandalRepository(const [_pinned]),
      location: location,
    );
    await tapAlertsSwitch(tester);

    expect(find.textContaining('Location access is blocked'), findsOneWidget);
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    expect(location.settingsOpened, [LocationAccess.deniedForever]);
  });

  testWidgets('declined notifications keep alerts off and point to Settings', (
    tester,
  ) async {
    final location = FakeLocationSource();
    await pumpApp(
      tester,
      data: PandalRepository(const [_pinned]),
      location: location,
      presenter: FakeAlertPresenter(canNotify: false),
    );
    await tapAlertsSwitch(tester);

    expect(find.textContaining('Notifications are off'), findsOneWidget);
    expect(location.isListened, isFalse);
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    expect(location.settingsOpened, [LocationAccess.deniedForever]);
  });

  testWidgets('alerts left on come back on at launch without asking', (
    tester,
  ) async {
    final location = FakeLocationSource();
    await pumpApp(
      tester,
      data: PandalRepository(const [_pinned]),
      location: location,
      storage: MemoryStorage(nearbyAlertsOn: true),
    );

    expect(location.isListened, isTrue);
    expect(location.calls, ['checkAccess']);
    expect(
      find.textContaining('On. You’ll be notified', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('a notification that launched the app opens its pandal', (
    tester,
  ) async {
    await pumpApp(
      tester,
      data: PandalRepository(const [_pinned]),
      presenter: FakeAlertPresenter(launchedFrom: 'test-pinned'),
    );
    expect(find.text('Visiting Hours'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Explore Pandals'), findsOneWidget);
  });

  testWidgets('favourites survive a restart', (tester) async {
    final storage = MemoryStorage(favouriteIds: const ['no-longer-listed']);
    await pumpApp(tester, storage: storage);
    await openTab(tester, 'Favourites');
    expect(find.text('No favourites yet'), findsOneWidget);

    await openTab(tester, 'Pandals');
    await tester.tap(find.byTooltip('Add to favourites').first);
    await tester.pumpAndSettle();
    final saved = repository.pandals.first.id;
    expect(storage.favouriteIds, [saved]);

    // Close the app and launch it again.
    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester, storage: storage);
    await openTab(tester, 'Favourites');
    expect(find.text('1 saved pandal'), findsOneWidget);
    expect(
      find.text('Airports Authority of India Community Hall'),
      findsOneWidget,
    );
  });

  testWidgets('the Favourites tab lists hearted pandals', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Your favourites'));
    await tester.pumpAndSettle();
    expect(find.text('No favourites yet'), findsOneWidget);

    await tester.tap(find.text('Browse pandals'));
    await tester.pumpAndSettle();
    expect(find.text('All Pandals'), findsOneWidget);
    await tester.tap(find.byTooltip('Add to favourites').first);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byType(NavigationBar), matching: find.text('1')),
      findsOneWidget,
      reason: 'the tab shows how many are saved',
    );

    await openTab(tester, 'Favourites');
    expect(find.text('1 saved pandal'), findsOneWidget);
    expect(
      find.text('Airports Authority of India Community Hall'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Remove from favourites'));
    await tester.pumpAndSettle();
    expect(find.text('No favourites yet'), findsOneWidget);
  });

  void reduceMotion(WidgetTester tester) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  testWidgets('the splash decodes Home images early and then frees its art', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // rootBundle caches the list's load from an earlier test, in that test's
    // fake-async zone, where it would never complete for this one.
    rootBundle.evict(PandalRepository.assetPath);
    final cache = PaintingBinding.instance.imageCache;
    ImageCacheStatus status(String asset) => cache.statusForKey(
      AssetBundleImageKey(bundle: rootBundle, name: asset, scale: 1),
    );

    await tester.pumpWidget(
      DurgaDarshanApp(
        storage: MemoryStorage(),
        mapTileProvider: FakeTileProvider(),
        locationSource: FakeLocationSource(),
        alertPresenter: FakeAlertPresenter(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Explore Pandals'), findsNothing, reason: 'still splash');
    for (final asset in AppImages.shownAtLaunch) {
      expect(status(asset).tracked, isTrue, reason: asset);
    }
    expect(status(AppImages.splashArt).tracked, isTrue);

    await tester.pump(AppMotion.splashMinimum);
    await tester.pumpAndSettle();
    expect(find.text('Explore Pandals'), findsOneWidget);
    for (final asset in AppImages.splashOnly) {
      expect(status(asset).untracked, isTrue, reason: asset);
    }
  });

  testWidgets('with reduced motion the splash shows its final state at once', (
    tester,
  ) async {
    reduceMotion(tester);
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      DurgaDarshanApp(
        storage: MemoryStorage(),
        mapTileProvider: FakeTileProvider(),
        locationSource: FakeLocationSource(),
        alertPresenter: FakeAlertPresenter(),
      ),
    );
    await tester.pump();
    expect(find.text('Durga\nDarshan'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);

    // Let the splash timer finish before the test ends.
    await tester.pump(AppMotion.splashMinimum);
    await tester.pumpAndSettle();
  });

  /// Whether nothing above [finder] is still faded out.
  bool fullyShown(Finder finder) {
    var shown = true;
    finder.evaluate().first.visitAncestorElements((ancestor) {
      final widget = ancestor.widget;
      if (widget is Opacity && widget.opacity < 1) shown = false;
      if (widget is FadeTransition && widget.opacity.value < 1) shown = false;
      return shown;
    });
    return shown;
  }

  testWidgets('with reduced motion screens and pages appear without motion', (
    tester,
  ) async {
    reduceMotion(tester);
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      DurgaDarshanApp(
        repository: loadBundledPandals(),
        mapTileProvider: FakeTileProvider(),
        locationSource: FakeLocationSource(),
        alertPresenter: FakeAlertPresenter(),
      ),
    );
    await tester.pump();
    // No reveal runs on Home.
    expect(tester.hasRunningAnimations, isFalse);
    expect(fullyShown(find.text('Explore Pandals')), isTrue);
    expect(fullyShown(find.byType(FeaturedPandalCard)), isTrue);

    // Each tab is fully shown on the first frame after switching. (Taps
    // still draw Material's ink ripple, which isn't app motion.)
    Future<void> switchTo(String tab) async {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(tab),
        ),
      );
      await tester.pump();
    }

    await switchTo('Pandals');
    expect(fullyShown(find.byType(PandalListCard)), isTrue);
    await switchTo('Map');
    expect(fullyShown(find.byType(PandalPin)), isTrue);
    expect(fullyShown(find.text('Pandal Map')), isTrue);
    await switchTo('Favourites');
    expect(fullyShown(find.text('No favourites yet')), isTrue);
    await switchTo('Home');

    // A pushed route is offstage for its first frame while heroes are
    // measured; on the next it is fully there.
    await tester.tap(find.byType(FeaturedPandalCard).first);
    await tester.pump();
    await tester.pump();
    expect(fullyShown(find.text('Visiting Hours')), isTrue);
    expect(fullyShown(find.text('Add to Favourites')), isTrue);
    await tester.pumpAndSettle();
  });

  testWidgets('wide layouts use a navigation rail', (tester) async {
    await pumpApp(tester, size: const Size(1280, 900));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
