import 'package:durga_darshan/models/visit.dart';
import 'package:durga_darshan/state/visits_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final evening = DateTime(2026, 10, 17, 19, 5);

  group('Visit', () {
    test('round-trips through its stored form', () {
      for (final visit in [
        Visit(pandalId: 'a', visitedAt: evening),
        Visit(pandalId: 'a', visitedAt: evening, rating: 4, note: 'Lovely'),
      ]) {
        expect(Visit.tryDecode(visit.encode()), visit);
      }
    });

    test('unreadable records are skipped, not thrown', () {
      for (final record in [
        'not json',
        '[]',
        '{"visitedAt": "2026-10-17T19:05:00.000"}',
        '{"pandalId": "a", "visitedAt": "yesterday"}',
        '{"pandalId": "a", "visitedAt": "2026-10-17T19:05:00.000", '
            '"rating": 6}',
        '{"pandalId": "a", "visitedAt": "2026-10-17T19:05:00.000", '
            '"note": 3}',
      ]) {
        expect(Visit.tryDecode(record), isNull, reason: record);
      }
    });

    test('formats dates and times for people', () {
      final now = DateTime(2026, 10, 18);
      expect(formatVisitDateTime(evening, now: now), 'Sat 17 Oct, 7:05 pm');
      expect(formatVisitTime(DateTime(2026, 10, 17, 0, 30)), '12:30 am');
      expect(formatVisitTime(DateTime(2026, 10, 17, 12)), '12:00 pm');
      expect(
        formatVisitDate(evening, now: DateTime(2027, 1, 2)),
        'Sat 17 Oct 2026',
      );
    });
  });

  group('VisitsController', () {
    test('saves, replaces and removes visits, newest first', () {
      final visits = VisitsController();
      var changes = 0;
      visits.addListener(() => changes++);

      final first = Visit(pandalId: 'a', visitedAt: evening);
      final later = Visit(
        pandalId: 'b',
        visitedAt: evening.add(const Duration(hours: 1)),
        rating: 5,
      );
      visits
        ..save(first)
        ..save(later);
      expect(visits.count, 2);
      expect(visits.visits, [later, first]);
      expect(visits.isVisited('a'), isTrue);

      visits.save(first); // unchanged
      expect(changes, 2);

      final rated = Visit(pandalId: 'a', visitedAt: evening, rating: 3);
      visits.save(rated);
      expect(visits.visitOf('a'), rated);
      expect(visits.count, 2);

      visits.remove('a');
      visits.remove('a'); // already gone
      expect(visits.isVisited('a'), isFalse);
      expect(changes, 4);
    });
  });
}
