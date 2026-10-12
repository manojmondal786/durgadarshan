import 'package:durga_darshan/app.dart';
import 'package:durga_darshan/data/pandal_repository.dart';
import 'package:durga_darshan/services/app_storage.dart';
import 'package:durga_darshan/widgets/map/pins.dart';
import 'package:durga_darshan/widgets/map/previews.dart';
import 'package:durga_darshan/widgets/pandal_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_location.dart';
import 'helpers/fake_tiles.dart';
import 'helpers/test_data.dart';

/// Visits every screen at phone, tablet and desktop sizes. Any overflow or
/// layout error fails the test.
void main() {
  const sizes = {
    'small Android phone': Size(320, 568),
    'common Android phone': Size(360, 640),
    'large phone': Size(412, 915),
    'tablet portrait': Size(800, 1280),
    'desktop browser': Size(1280, 800),
  };

  Future<void> pumpApp(
    WidgetTester tester,
    Size size,
    PandalRepository repository, {
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      DurgaDarshanApp(
        storage: MemoryStorage(),
        repository: repository,
        mapTileProvider: FakeTileProvider(),
        locationSource: FakeLocationSource(),
        alertPresenter: FakeAlertPresenter(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    final bar = find.byWidgetPredicate(
      (widget) => widget is NavigationBar || widget is NavigationRail,
    );
    await tester.tap(find.descendant(of: bar, matching: find.text(label)));
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> visitEveryScreen(WidgetTester tester) async {
    // Home, scrolled to the end.
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -4000),
    );
    await tester.pumpAndSettle();

    // Save the parking spot.
    await tapVisible(tester, find.text('Save My Parking'));
    expect(find.text('Navigate to my vehicle'), findsOneWidget);

    await openTab(tester, 'Pandals');
    await tester.tap(find.byTooltip('Add to favourites').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PandalListCard).first);
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(CustomScrollView).last,
      const Offset(0, -2000),
    );
    await tester.pumpAndSettle();

    // Mark it as visited, with a rating and a long note.
    await tapVisible(tester, find.text('Mark as visited'));
    await tester.tap(find.byTooltip('Rate 5 out of 5'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Note (optional)'),
      'The idol, the lighting and the bhog were all wonderful, and the '
      'cultural programme in the evening drew a big crowd.',
    );
    await tapVisible(tester, find.text('Mark visited'));
    expect(find.text('Visited'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await openTab(tester, 'Map');
    expect(find.byType(FlutterMap), findsOneWidget);
    final pins = find.byType(PandalPin);
    if (pins.evaluate().isNotEmpty) {
      await tester.tap(pins.first, warnIfMissed: false);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byTooltip('Show my parked vehicle'));
    await tester.pumpAndSettle();
    expect(find.byType(ParkingMapPreview), findsOneWidget);

    await openTab(tester, 'Favourites');
    expect(find.byType(PandalListCard), findsOneWidget);

    // My Darshan, from Home.
    await openTab(tester, 'Home');
    await tapVisible(tester, find.text('My Darshan'));
    expect(find.text('Visited · 1'), findsOneWidget);
    await tester.drag(
      find.byType(CustomScrollView).last,
      const Offset(0, -3000),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
  }

  for (final MapEntry(key: name, value: size) in sizes.entries) {
    testWidgets('every screen lays out on a $name', (tester) async {
      await pumpApp(tester, size, loadBundledPandals());
      await visitEveryScreen(tester);
    });
  }

  testWidgets('every screen lays out with larger text on a small phone', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const Size(360, 640),
      loadBundledPandals(),
      textScale: 1.3,
    );
    await visitEveryScreen(tester);
  });
}
