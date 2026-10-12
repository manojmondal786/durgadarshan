import 'package:durga_darshan/models/pandal.dart';
import 'package:durga_darshan/models/visiting_hours.dart';
import 'package:durga_darshan/theme/app_theme.dart';
import 'package:durga_darshan/widgets/about_pandal_card.dart';
import 'package:durga_darshan/widgets/visiting_hours_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_data.dart';

const _tentative = Pandal(
  id: 'test-tentative',
  name: 'Test Tentative',
  area: 'Test Area',
  city: 'Ahmedabad',
  planningCutoff: ClockTime(0, 0),
);

const _poster = Pandal(
  id: 'test-poster',
  name: 'Test Poster',
  area: 'Test Area',
  city: 'Ahmedabad',
  timings: 'Morning 9 to 12.30',
  schedule: VisitingSchedule(
    source: ScheduleSource.poster,
    sessions: [
      VisitingSession(
        label: 'Morning visiting',
        start: ClockTime(9, 0),
        end: ClockTime(12, 30),
      ),
    ],
    events: [ScheduledEvent(label: 'Evening Aarti', time: ClockTime(20, 0))],
  ),
);

const _unknown = Pandal(
  id: 'test-unknown',
  name: 'Test Unknown',
  area: 'Test Area',
  city: 'Ahmedabad',
);

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(400, 800),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }

  group('VisitingHoursCard', () {
    testWidgets('labels a tentative cutoff as estimated, with disclaimer', (
      tester,
    ) async {
      await pump(tester, const VisitingHoursCard(pandal: _tentative));

      expect(find.text('Visiting Hours'), findsOneWidget);
      expect(find.text('Estimated · Not Confirmed'), findsOneWidget);
      expect(
        find.text('Until 12:00 AM (Midnight) — Tentative', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.text(
          'Midnight is a tentative planning cutoff, not a confirmed closing '
          'time. Actual visiting hours may differ. Please confirm before '
          'visiting.',
        ),
        findsOneWidget,
      );
      expect(find.text(VisitingHoursCard.posterTag), findsNothing);
    });

    testWidgets('shows poster hours with their source and no cutoff', (
      tester,
    ) async {
      await pump(tester, const VisitingHoursCard(pandal: _poster));

      expect(
        find.text('Poster Source · Not Independently Confirmed'),
        findsOneWidget,
      );
      expect(find.text('Morning visiting'), findsOneWidget);
      expect(find.text('9:00 AM – 12:30 PM'), findsOneWidget);
      expect(find.text('Evening Aarti'), findsOneWidget);
      expect(find.text('8:00 PM'), findsOneWidget);
      expect(find.text(VisitingHoursCard.estimatedTag), findsNothing);
      expect(find.text(VisitingHoursCard.cutoffDisclaimer), findsNothing);
    });

    testWidgets('says hours are not announced when there are none', (
      tester,
    ) async {
      await pump(tester, const VisitingHoursCard(pandal: _unknown));

      expect(find.text('Not announced yet'), findsOneWidget);
      expect(find.text(VisitingHoursCard.estimatedTag), findsNothing);
      expect(find.text(VisitingHoursCard.posterTag), findsNothing);
    });

    testWidgets('every bundled pandal is labelled as poster or estimated', (
      tester,
    ) async {
      for (final pandal in loadBundledPandals().pandals) {
        await pump(tester, VisitingHoursCard(pandal: pandal));
        final isPoster = pandal.id == 'chatterjee-barir-pujo';
        expect(
          find.text(VisitingHoursCard.posterTag),
          isPoster ? findsOneWidget : findsNothing,
          reason: pandal.id,
        );
        expect(
          find.text(VisitingHoursCard.estimatedTag),
          isPoster ? findsNothing : findsOneWidget,
          reason: pandal.id,
        );
      }
    });
  });

  group('AboutPandalCard', () {
    testWidgets('shows each paragraph of the description', (tester) async {
      await pump(
        tester,
        const AboutPandalCard(description: 'First paragraph.\n\nSecond one.'),
      );

      expect(find.text('About this Pandal'), findsOneWidget);
      expect(find.text('First paragraph.'), findsOneWidget);
      expect(find.text('Second one.'), findsOneWidget);
      expect(find.text(AboutPandalCard.placeholder), findsNothing);
    });

    testWidgets('falls back to a placeholder without a description', (
      tester,
    ) async {
      await pump(tester, const AboutPandalCard(description: null));

      expect(find.text(AboutPandalCard.placeholder), findsOneWidget);
    });
  });

  testWidgets('both cards fit a small phone with larger text', (tester) async {
    final kalibari = loadBundledPandals().byId('ahmedabad-kalibari')!;
    for (final pandal in [_tentative, _poster, kalibari]) {
      await pump(
        tester,
        Column(
          children: [
            VisitingHoursCard(pandal: pandal),
            AboutPandalCard(description: pandal.description),
          ],
        ),
        size: const Size(320, 568),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull, reason: pandal.id);
    }
  });
}
