import 'package:durga_darshan/models/pandal.dart';
import 'package:durga_darshan/services/external_maps.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Synthetic test fixture, not real pandal data.
  const verified = Pandal(
    id: 'test-verified',
    name: 'Test Pandal (Hall 2)',
    area: 'Test Area',
    city: 'Ahmedabad',
    latitude: 23.0225,
    longitude: 72.5714,
    verificationStatus: VerificationStatus.verified,
  );

  final realOpener = ExternalMaps.opener;
  late List<Uri> opened;

  setUp(() => opened = []);
  tearDown(() => ExternalMaps.opener = realOpener);

  void useOpener(bool Function(Uri uri) handles) {
    ExternalMaps.opener = (uri) async {
      opened.add(uri);
      return handles(uri);
    };
  }

  group('linkFor', () {
    test('Android opens a geo: URI with a web fallback', () {
      final link = ExternalMaps.linkFor(
        verified,
        platform: TargetPlatform.android,
        isWeb: false,
      );

      expect(
        link.primary.toString(),
        'geo:23.022500,72.571400?q=23.022500,72.571400(Test%20Pandal%20Hall%202)',
      );
      expect(
        link.fallback.toString(),
        'https://www.openstreetmap.org/?mlat=23.022500&mlon=72.571400'
        '#map=18/23.022500/72.571400',
      );
    });

    test('iOS opens Apple Maps with the pandal as destination', () {
      final link = ExternalMaps.linkFor(
        verified,
        platform: TargetPlatform.iOS,
        isWeb: false,
      );

      expect(link.primary.scheme, 'https');
      expect(link.primary.host, 'maps.apple.com');
      expect(link.primary.queryParameters, {
        'daddr': '23.022500,72.571400',
        'q': 'Test Pandal (Hall 2)',
      });
      expect(link.fallback?.host, 'www.openstreetmap.org');
    });

    test('web and desktop open the OpenStreetMap website', () {
      for (final link in [
        ExternalMaps.linkFor(verified, isWeb: true),
        ExternalMaps.linkFor(
          verified,
          platform: TargetPlatform.linux,
          isWeb: false,
        ),
      ]) {
        expect(link.primary.host, 'www.openstreetmap.org');
        expect(link.primary.queryParameters, {
          'mlat': '23.022500',
          'mlon': '72.571400',
        });
        expect(link.fallback, isNull);
      }
    });

    test('refuses pandals without a verified location', () {
      const unverifiedWithCoordinates = Pandal(
        id: 'test-unverified',
        name: 'Test',
        area: 'Test Area',
        city: 'Ahmedabad',
        latitude: 23.0225,
        longitude: 72.5714,
      );
      const verifiedWithoutCoordinates = Pandal(
        id: 'test-no-coordinates',
        name: 'Test',
        area: 'Test Area',
        city: 'Ahmedabad',
        verificationStatus: VerificationStatus.verified,
      );

      expect(
        () => ExternalMaps.linkFor(unverifiedWithCoordinates),
        throwsArgumentError,
      );
      expect(
        () => ExternalMaps.linkFor(verifiedWithoutCoordinates),
        throwsArgumentError,
      );
    });
  });

  group('open', () {
    final link = MapsLink(
      Uri.parse('geo:1,2'),
      Uri.parse('https://example.org/fallback'),
    );

    test('stops at the primary link when it opens', () async {
      useOpener((_) => true);
      expect(await ExternalMaps.open(link), isTrue);
      expect(opened, [link.primary]);
    });

    test(
      'falls back to the web link when no app handles the primary',
      () async {
        useOpener((uri) => uri.scheme == 'https');
        expect(await ExternalMaps.open(link), isTrue);
        expect(opened, [link.primary, link.fallback]);
      },
    );

    test('reports failure instead of throwing', () async {
      ExternalMaps.opener = (uri) async {
        opened.add(uri);
        throw Exception('No handler');
      };
      expect(await ExternalMaps.open(link), isFalse);
      expect(opened, hasLength(2));
    });
  });

  group('addressSearchQueries', () {
    Pandal pandal({String? address, String city = 'Ahmedabad'}) => Pandal(
      id: 'test',
      name: 'Test Hall',
      area: 'Test Area',
      city: city,
      address: address,
    );

    test('combines name, address and a missing city', () {
      expect(
        ExternalMaps.addressSearchQueries(
          pandal(address: 'near seventh day school, Maninagar.'),
        ),
        ['Test Hall, near seventh day school, Maninagar, Ahmedabad'],
      );
    });

    test('does not repeat a city the address already names', () {
      expect(
        ExternalMaps.addressSearchQueries(
          pandal(address: 'Amrut bagh, Bavla, Ahmedabad.', city: 'Bavla'),
        ),
        ['Test Hall, Amrut bagh, Bavla, Ahmedabad'],
      );
    });

    test('gives one search per alternative venue', () {
      expect(
        ExternalMaps.addressSearchQueries(
          pandal(
            address:
                'Savvy Swaraj, Gota, Ahmedabad. / Godrej Garden City '
                'ground, behind police booth, Jagatpur.',
          ),
        ),
        [
          'Test Hall, Savvy Swaraj, Gota, Ahmedabad',
          'Test Hall, Godrej Garden City ground, behind police booth, '
              'Jagatpur, Ahmedabad',
        ],
      );
    });

    test('keeps slashes that are part of an address', () {
      expect(
        ExternalMaps.addressSearchQueries(
          pandal(address: 'b/h sunrise mall, Vastrapur, Ahmedabad.'),
        ),
        hasLength(1),
      );
    });

    test('returns nothing without an address', () {
      expect(ExternalMaps.addressSearchQueries(pandal()), isEmpty);
    });
  });

  group('searchFor', () {
    const query = 'Test Hall, near school, Maninagar, Ahmedabad';

    test('Android searches in the user\'s maps app via geo:', () {
      final link = ExternalMaps.searchFor(
        query,
        platform: TargetPlatform.android,
        isWeb: false,
      );

      expect(
        link.primary.toString(),
        'geo:0,0?q=Test%20Hall%2C%20near%20school%2C%20Maninagar%2C%20Ahmedabad',
      );
      expect(link.fallback?.host, 'www.google.com');
      expect(link.fallback?.queryParameters, {'api': '1', 'query': query});
    });

    test('iOS searches in Apple Maps', () {
      final link = ExternalMaps.searchFor(
        query,
        platform: TargetPlatform.iOS,
        isWeb: false,
      );

      expect(link.primary.host, 'maps.apple.com');
      expect(link.primary.queryParameters, {'q': query});
    });

    test('web and desktop search on the Google Maps website', () {
      for (final link in [
        ExternalMaps.searchFor(query, isWeb: true),
        ExternalMaps.searchFor(
          query,
          platform: TargetPlatform.windows,
          isWeb: false,
        ),
      ]) {
        expect(link.primary.host, 'www.google.com');
        expect(link.primary.path, '/maps/search/');
        expect(link.primary.queryParameters, {'api': '1', 'query': query});
        expect(link.fallback, isNull);
      }
    });

    test('never contains coordinates', () {
      final link = ExternalMaps.searchFor(
        query,
        platform: TargetPlatform.android,
        isWeb: false,
      );
      expect(link.primary.path, '0,0');
    });
  });
}
