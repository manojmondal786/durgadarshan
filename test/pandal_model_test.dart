import 'package:durga_darshan/models/pandal.dart';
import 'package:durga_darshan/models/visiting_hours.dart';
import 'package:flutter_test/flutter_test.dart';

const _posterSchedule = {
  'source': 'poster',
  'sessions': [
    {'label': 'Morning visiting', 'start': '09:00', 'end': '12:30'},
  ],
  'events': [
    {'label': 'Evening Aarti', 'time': '20:00'},
  ],
};

Map<String, Object?> record([Map<String, Object?> overrides = const {}]) => {
  'id': 'test-pandal',
  'posterNumber': 1,
  'name': 'Test Pandal',
  'area': 'Test Area',
  'city': 'Ahmedabad',
  'address': 'Test address',
  'latitude': null,
  'longitude': null,
  'verificationStatus': 'unverified',
  'timings': null,
  'description': null,
  'image': null,
  'notes': null,
  ...overrides,
};

void main() {
  group('Pandal.fromJson', () {
    test('parses a complete record', () {
      final pandal = Pandal.fromJson(
        record({
          'timings': '6 to 9 pm',
          'description': 'About text',
          'image': 'assets/images/pandals/test.jpg',
          'notes': ['First note', 'Second note'],
          'verificationStatus': 'conflicting',
        }),
      );

      expect(pandal.id, 'test-pandal');
      expect(pandal.posterNumber, 1);
      expect(pandal.name, 'Test Pandal');
      expect(pandal.area, 'Test Area');
      expect(pandal.city, 'Ahmedabad');
      expect(pandal.address, 'Test address');
      expect(pandal.timings, '6 to 9 pm');
      expect(pandal.description, 'About text');
      expect(pandal.imageAsset, 'assets/images/pandals/test.jpg');
      expect(pandal.notes, ['First note', 'Second note']);
      expect(pandal.verificationStatus, VerificationStatus.conflicting);
      expect(pandal.isFeatured, isFalse);
    });

    test('treats null and blank optional fields as unknown', () {
      final pandal = Pandal.fromJson(
        record({'address': '   ', 'timings': '', 'notes': null}),
      );

      expect(pandal.address, isNull);
      expect(pandal.timings, isNull);
      expect(pandal.description, isNull);
      expect(pandal.imageAsset, isNull);
      expect(pandal.notes, isEmpty);
    });

    test('maps every verification status', () {
      const expected = {
        'verified': VerificationStatus.verified,
        'unverified': VerificationStatus.unverified,
        'needs_check': VerificationStatus.needsCheck,
        'conflicting': VerificationStatus.conflicting,
      };
      expected.forEach((json, status) {
        expect(
          Pandal.fromJson(record({'verificationStatus': json}))
              .verificationStatus,
          status,
        );
      });
    });

    test('rejects malformed records', () {
      final invalid = <String, Map<String, Object?>>{
        'missing name': record()..remove('name'),
        'blank id': record({'id': '  '}),
        'non-string area': record({'area': 42}),
        'latitude without longitude': record({'latitude': 23.0}),
        'longitude without latitude': record({'longitude': 72.5}),
        'latitude out of range': record({'latitude': 123.0, 'longitude': 72.5}),
        'longitude out of range': record({
          'latitude': 23.0,
          'longitude': 272.5,
        }),
        'string coordinate': record({'latitude': '23.0', 'longitude': 72.5}),
        'unknown status': record({'verificationStatus': 'probably'}),
        'notes not a list': record({'notes': 'a note'}),
        'blank note': record({
          'notes': ['  '],
        }),
        'fractional poster number': record({'posterNumber': 1.5}),
        'cutoff that is not tentative': record({
          'planningCutoff': {'time': '00:00', 'status': 'confirmed'},
        }),
        'cutoff with a bad time': record({
          'planningCutoff': {'time': '24:00', 'status': 'tentative'},
        }),
        'cutoff beside real hours': record({
          'schedule': _posterSchedule,
          'planningCutoff': {'time': '00:00', 'status': 'tentative'},
        }),
        'unknown schedule source': record({
          'schedule': {..._posterSchedule, 'source': 'rumour'},
        }),
        'empty schedule': record({
          'schedule': {'source': 'poster'},
        }),
        'session without an end': record({
          'schedule': {
            'source': 'poster',
            'sessions': [
              {'label': 'Morning', 'start': '09:00'},
            ],
          },
        }),
      };
      invalid.forEach((reason, json) {
        expect(
          () => Pandal.fromJson(json),
          throwsFormatException,
          reason: reason,
        );
      });
    });
  });

  group('visiting hours', () {
    test('parses a poster schedule apart from the printed text', () {
      final pandal = Pandal.fromJson(
        record({'timings': 'Morning 9 to 12.30', 'schedule': _posterSchedule}),
      );

      expect(pandal.timings, 'Morning 9 to 12.30');
      expect(pandal.planningCutoff, isNull);
      final schedule = pandal.schedule!;
      expect(schedule.source, ScheduleSource.poster);
      expect(schedule.sessions.single.label, 'Morning visiting');
      expect(schedule.sessions.single.start, const ClockTime(9, 0));
      expect(schedule.sessions.single.end, const ClockTime(12, 30));
      expect(schedule.events.single.label, 'Evening Aarti');
      expect(schedule.events.single.time, const ClockTime(20, 0));
    });

    test('keeps a tentative cutoff out of the actual hours', () {
      final pandal = Pandal.fromJson(
        record({
          'planningCutoff': {'time': '00:00', 'status': 'tentative'},
        }),
      );

      expect(pandal.planningCutoff, const ClockTime(0, 0));
      expect(pandal.planningCutoff!.isMidnight, isTrue);
      expect(pandal.schedule, isNull);
      expect(pandal.timings, isNull);
    });

    test('formats times on a 12-hour clock', () {
      expect(const ClockTime(0, 0).format(), '12:00 AM');
      expect(const ClockTime(9, 0).format(), '9:00 AM');
      expect(const ClockTime(12, 30).format(), '12:30 PM');
      expect(const ClockTime(18, 5).format(), '6:05 PM');
      expect(ClockTime.parse('20:00').format(), '8:00 PM');
      for (final bad in ['8:00', '24:00', '12:60', '8 pm', null]) {
        expect(() => ClockTime.parse(bad), throwsFormatException);
      }
    });
  });

  group('location handling', () {
    test('missing coordinates are never a verified location', () {
      final pandal = Pandal.fromJson(
        record({'verificationStatus': 'verified'}),
      );

      expect(pandal.hasCoordinates, isFalse);
      expect(pandal.isLocationVerified, isTrue);
      expect(pandal.hasVerifiedLocation, isFalse);
    });

    test('coordinates are only trusted once verified', () {
      final coordinates = {'latitude': 23.03, 'longitude': 72.58};
      final unverified = Pandal.fromJson(record(coordinates));
      final verified = Pandal.fromJson(
        record({...coordinates, 'verificationStatus': 'verified'}),
      );

      expect(unverified.hasCoordinates, isTrue);
      expect(unverified.hasVerifiedLocation, isFalse);
      expect(verified.hasVerifiedLocation, isTrue);
      expect(verified.latitude, 23.03);
      expect(verified.longitude, 72.58);
    });
  });
}
