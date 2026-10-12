import 'package:durga_darshan/models/pandal.dart';
import 'package:flutter_test/flutter_test.dart';

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
