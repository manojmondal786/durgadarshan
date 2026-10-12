import 'package:durga_darshan/app.dart';
import 'package:durga_darshan/data/pandal_repository.dart';
import 'package:durga_darshan/models/pandal.dart';
import 'package:durga_darshan/models/visit.dart';
import 'package:durga_darshan/services/app_storage.dart';
import 'package:durga_darshan/widgets/pandal_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_location.dart';
import 'helpers/fake_tiles.dart';
import 'helpers/test_data.dart';

void main() {
  late PandalRepository repository;

  setUpAll(() => repository = loadBundledPandals());

  /// A time earlier today, to the minute, so the visit sheet accepts it.
  DateTime hoursAgo(int hours) {
    final time = DateTime.now().subtract(Duration(hours: hours));
    return DateTime(time.year, time.month, time.day, time.hour, time.minute);
  }

  String record(Pandal pandal, DateTime at, {int? rating, String? note}) =>
      Visit(
        pandalId: pandal.id,
        visitedAt: at,
        rating: rating,
        note: note,
      ).encode();

  Future<void> pumpApp(
    WidgetTester tester, {
    required AppStorage storage,
    PandalRepository? data,
  }) async {
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      DurgaDarshanApp(
        repository: data ?? repository,
        storage: storage,
        mapTileProvider: FakeTileProvider(),
        locationSource: FakeLocationSource(),
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

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openTracker(WidgetTester tester) async {
    await openTab(tester, 'Home');
    await tapVisible(tester, find.text('My Darshan'));
  }

  testWidgets('marking a pandal as visited, with a rating and a note', (
    tester,
  ) async {
    final storage = MemoryStorage();
    final pandal = repository.pandals.first;
    await pumpApp(tester, storage: storage);
    expect(
      find.text('Mark pandals as visited and track all 25'),
      findsOneWidget,
    );

    await openTab(tester, 'Pandals');
    await tester.tap(find.byType(PandalListCard).first);
    await tester.pumpAndSettle();
    expect(find.text('Been here?'), findsOneWidget);

    await tapVisible(tester, find.text('Mark as visited'));
    expect(find.text(pandal.name), findsWidgets);
    await tester.tap(find.byTooltip('Rate 4 out of 5'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Note (optional)'),
      '  Beautiful idol  ',
    );
    await tester.tap(find.text('Mark visited'));
    await tester.pumpAndSettle();

    expect(find.text('Visited'), findsOneWidget);
    expect(find.text('Beautiful idol'), findsOneWidget);
    expect(find.bySemanticsLabel('Rated 4 out of 5'), findsOneWidget);
    final saved = Visit.tryDecode(storage.visitRecords.single)!;
    expect(saved.pandalId, pandal.id);
    expect(saved.rating, 4);
    expect(saved.note, 'Beautiful idol');
    expect(
      DateTime.now().difference(saved.visitedAt).inMinutes,
      lessThan(2),
      reason: 'defaults to now',
    );

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(PandalListCard).first,
        matching: find.text('Visited'),
      ),
      findsOneWidget,
    );

    await openTab(tester, 'Home');
    expect(find.text('1 of 25 visited · 24 to go'), findsOneWidget);
  });

  testWidgets('the tracker lists visits, newest first, and what is left', (
    tester,
  ) async {
    final [first, second, third, ...] = repository.pandals;
    await pumpApp(
      tester,
      storage: MemoryStorage(
        visitRecords: [
          record(first, hoursAgo(5), note: 'Grand pandal'),
          record(second, hoursAgo(2), rating: 5),
        ],
      ),
    );
    expect(find.text('2 of 25 visited · 23 to go'), findsOneWidget);

    await openTracker(tester);
    expect(find.text('2 of 25 pandals visited'), findsOneWidget);
    expect(find.text('Visited · 2'), findsOneWidget);
    expect(find.text('Grand pandal'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(second.name)).dy,
      lessThan(tester.getTopLeft(find.text(first.name)).dy),
      reason: 'most recent visit first',
    );

    await tapVisible(tester, find.text('Still to visit · 23'));
    await tapVisible(tester, find.text(third.name));
    expect(find.text('Been here?'), findsOneWidget);
  });

  testWidgets('editing a visit, and removing it with undo', (tester) async {
    final pandal = repository.pandals.first;
    final storage = MemoryStorage(
      visitRecords: [record(pandal, hoursAgo(1), rating: 2)],
    );
    await pumpApp(tester, storage: storage);
    await openTab(tester, 'Pandals');
    await tester.tap(find.byType(PandalListCard).first);
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Edit visit'));
    expect(find.text('Edit your visit'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear rating')); // the current 2 stars
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(Visit.tryDecode(storage.visitRecords.single)!.rating, isNull);

    await tapVisible(tester, find.text('Edit visit'));
    await tester.tap(find.text('Remove visit'));
    await tester.pumpAndSettle();
    expect(find.text('Been here?'), findsOneWidget);
    expect(storage.visitRecords, isEmpty);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Visited'), findsOneWidget);
    expect(storage.visitRecords, hasLength(1));
  });

  testWidgets('visiting every pandal is celebrated', (tester) async {
    final two = PandalRepository(repository.pandals.take(2).toList());
    await pumpApp(
      tester,
      data: two,
      storage: MemoryStorage(
        visitRecords: [
          for (final pandal in two.pandals) record(pandal, hoursAgo(1)),
        ],
      ),
    );
    expect(find.text('All 2 visited. Joy Maa Durga!'), findsOneWidget);

    await openTracker(tester);
    expect(find.text('You’ve visited all 2 pandals!'), findsOneWidget);
    expect(find.textContaining('Still to visit'), findsNothing);
  });

  testWidgets('visits survive a restart; unreadable ones are skipped', (
    tester,
  ) async {
    final storage = MemoryStorage(
      visitRecords: [
        record(repository.pandals.first, hoursAgo(1)),
        'not a visit',
        record(
          const Pandal(id: 'gone', name: 'Gone', area: 'X', city: 'Y'),
          hoursAgo(1),
        ),
      ],
    );
    await pumpApp(tester, storage: storage);
    expect(find.text('1 of 25 visited · 24 to go'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester, storage: storage);
    expect(find.text('1 of 25 visited · 24 to go'), findsOneWidget);
  });
}
