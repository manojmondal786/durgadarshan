import 'package:durga_darshan/data/pandal_repository.dart';
import 'package:durga_darshan/models/coordinates.dart';
import 'package:durga_darshan/models/pandal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Coordinates', () {
    test('accepts latitudes within -90..90, inclusive', () {
      for (final value in [-90.0, -45.5, 0.0, 23.0225, 90.0]) {
        expect(Coordinates.isValidLatitude(value), isTrue, reason: '$value');
      }
    });

    test('rejects latitudes outside -90..90 and non-finite values', () {
      for (final value in [
        -90.0001,
        90.0001,
        180.0,
        double.nan,
        double.infinity,
        double.negativeInfinity,
        null,
      ]) {
        expect(Coordinates.isValidLatitude(value), isFalse, reason: '$value');
      }
    });

    test('accepts longitudes within -180..180, inclusive', () {
      for (final value in [-180.0, -72.5, 0.0, 72.5714, 180.0]) {
        expect(Coordinates.isValidLongitude(value), isTrue, reason: '$value');
      }
    });

    test('rejects longitudes outside -180..180 and non-finite values', () {
      for (final value in [
        -180.0001,
        180.0001,
        360.0,
        double.nan,
        double.infinity,
        null,
      ]) {
        expect(Coordinates.isValidLongitude(value), isFalse, reason: '$value');
      }
    });

    test('a pair needs both halves valid', () {
      expect(Coordinates.isValidPair(23.02, 72.57), isTrue);
      expect(Coordinates.isValidPair(23.02, null), isFalse);
      expect(Coordinates.isValidPair(null, 72.57), isFalse);
      expect(Coordinates.isValidPair(123.0, 72.57), isFalse);
      expect(Coordinates.isValidPair(23.02, 272.57), isFalse);
    });
  });

  group('marker eligibility', () {
    Pandal pandal(
      String id,
      VerificationStatus status, {
      double? latitude,
      double? longitude,
    }) => Pandal(
      id: id,
      name: id,
      area: 'Test Area',
      city: 'Ahmedabad',
      verificationStatus: status,
      latitude: latitude,
      longitude: longitude,
    );

    test('only verified pandals with valid coordinates get a pin', () {
      final repository = PandalRepository([
        pandal(
          'verified',
          VerificationStatus.verified,
          latitude: 23.0225,
          longitude: 72.5714,
        ),
        pandal(
          'verified-out-of-range',
          VerificationStatus.verified,
          latitude: 123.0,
          longitude: 72.5,
        ),
        pandal('verified-no-coordinates', VerificationStatus.verified),
        pandal(
          'unverified-with-coordinates',
          VerificationStatus.unverified,
          latitude: 23.0225,
          longitude: 72.5714,
        ),
        pandal(
          'needs-check-with-coordinates',
          VerificationStatus.needsCheck,
          latitude: 23.0225,
          longitude: 72.5714,
        ),
        pandal(
          'conflicting-with-coordinates',
          VerificationStatus.conflicting,
          latitude: 23.0225,
          longitude: 72.5714,
        ),
      ]);

      expect(repository.mappable.map((p) => p.id), ['verified']);
    });

    test('coordinates alone never make a location verified', () {
      final p = pandal(
        'unverified',
        VerificationStatus.unverified,
        latitude: 23.0225,
        longitude: 72.5714,
      );
      expect(p.hasCoordinates, isTrue);
      expect(p.hasVerifiedLocation, isFalse);
    });

    test('out-of-range coordinates are not treated as coordinates', () {
      final p = pandal(
        'bad',
        VerificationStatus.verified,
        latitude: 23.0,
        longitude: -181.0,
      );
      expect(p.hasCoordinates, isFalse);
      expect(p.hasVerifiedLocation, isFalse);
    });
  });
}
