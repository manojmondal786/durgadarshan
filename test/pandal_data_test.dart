import 'dart:convert';
import 'dart:io';

import 'package:durga_darshan/data/pandal_repository.dart';
import 'package:durga_darshan/models/coordinates.dart';
import 'package:durga_darshan/models/pandal.dart';
import 'package:durga_darshan/models/visiting_hours.dart';
import 'package:durga_darshan/screens/pandal_details_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/src/records.dart' as tool;

/// Checks the bundled data transcribed from the 2026 poster. These rules hold
/// however many locations have been verified since.
void main() {
  late Map<String, Object?> document;
  late List<Map<String, Object?>> records;
  late PandalRepository repository;

  setUpAll(() {
    final source = File(PandalRepository.assetPath).readAsStringSync();
    document = jsonDecode(source) as Map<String, Object?>;
    records = (document['pandals'] as List).cast<Map<String, Object?>>();
    repository = PandalRepository.fromJsonString(source);
  });

  test('contains all 25 poster entries with unique, stable ids', () {
    final pandals = repository.pandals;
    expect(pandals, hasLength(25));

    final ids = pandals.map((p) => p.id).toList();
    expect(ids.toSet(), hasLength(25));
    for (final id in ids) {
      expect(id, matches(RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$')), reason: id);
    }

    expect(pandals.map((p) => p.posterNumber), [
      for (var n = 1; n <= 25; n++) n,
    ]);
  });

  test('every record spells out every documented field', () {
    const fields = [
      'id',
      'name',
      'area',
      'city',
      'address',
      'latitude',
      'longitude',
      'verificationStatus',
      'timings',
      'description',
      'image',
      'notes',
    ];
    for (final record in records) {
      expect(record.keys, containsAll(fields), reason: '${record['id']}');
    }
  });

  test('passes the verification tool\'s integrity checks', () {
    // Valid statuses, coordinate pairs in range, verified entries with
    // coordinates, and a recorded source for every set of coordinates.
    expect(tool.validateDocument(document), isEmpty);
  });

  test('coordinates are either absent or a valid pair', () {
    for (final record in records) {
      final lat = record['latitude'] as num?;
      final lng = record['longitude'] as num?;
      expect(lat == null, lng == null, reason: '${record['id']}');
      if (lat != null) {
        expect(
          Coordinates.isValidPair(lat.toDouble(), lng!.toDouble()),
          isTrue,
          reason: '${record['id']}',
        );
      }
    }
  });

  test('every verified pandal records when and how it was confirmed', () {
    for (final record in records) {
      if (record['verificationStatus'] != 'verified') continue;
      final verification = record['verification'] as Map<String, Object?>;
      expect(
        verification['verifiedOn'],
        matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')),
        reason: '${record['id']}',
      );
      expect(verification['verificationNote'], isNotEmpty);
      expect(verification['statusBeforeVerification'], isNotNull);
    }
  });

  test('map pins follow verification status, never coordinates alone', () {
    final verifiedIds = [
      for (final record in records)
        if (record['verificationStatus'] == 'verified') record['id'],
    ];
    expect(repository.mappable.map((p) => p.id), verifiedIds);

    for (final pandal in repository.pandals) {
      expect(
        pandal.hasVerifiedLocation,
        pandal.verificationStatus == VerificationStatus.verified,
        reason: pandal.id,
      );
    }
  });

  test('poster flags are kept, including after verification', () {
    const posterFlags = {
      'ramkrishna-seva-kendra': 'needs_check',
      'mukhi-party-plot': 'needs_check',
      'savvy-swaraj-durgotsav': 'conflicting',
      'karnavati-bangiya-parishad': 'conflicting',
      'gandhinagar-sector-22': 'conflicting',
    };
    for (final record in records) {
      final id = record['id'];
      expect(
        tool.originalStatusOf(record),
        posterFlags[id] ?? 'unverified',
        reason: '$id',
      );
      if (posterFlags.containsKey(id)) {
        // Shown as notes, or kept hidden as poster cautions.
        expect(
          [...?record['notes'] as List?, ...?record['posterCautions'] as List?],
          isNotEmpty,
          reason: '$id',
        );
      }
    }
    final kalibari = records.firstWhere((r) => r['id'] == 'ahmedabad-kalibari');
    expect([
      ...?kalibari['notes'] as List?,
      ...?kalibari['posterCautions'] as List?,
    ], contains(contains('updated location')));
  });

  test('caution notes are kept in the data but out of the app', () {
    for (final record in records) {
      final cautions = record['posterCautions'] as List?;
      if (cautions == null) continue;
      expect(cautions, isNotEmpty, reason: '${record['id']}');
      final shown = repository.byId(record['id']! as String)!.notes;
      for (final caution in cautions) {
        expect(shown, isNot(contains(caution)), reason: '${record['id']}');
      }
    }
  });

  group('location hints', () {
    test('only area-level pins are flagged as showing the area', () {
      final areaIds = [
        for (final record in records)
          if ((record['verification'] as Map?)?['coordinatesPrecision'] ==
              'area')
            record['id'],
      ];
      expect(areaIds, hasLength(18));
      expect(
        repository.pandals.where((p) => p.pinShowsAreaOnly).map((p) => p.id),
        areaIds,
      );
    });

    test('the eight entries the poster doubts ask visitors to check', () {
      final flagged = repository.pandals.where((p) => p.venueNeedsChecking);
      expect(flagged.map((p) => p.posterNumber), [4, 5, 6, 15, 16, 17, 18, 21]);

      final withVenues = repository.pandals.where(
        (p) => p.listedVenues.isNotEmpty,
      );
      expect(withVenues.map((p) => p.posterNumber), [15, 17]);
    });

    test('address captions use friendly wording, not poster cautions', () {
      String? caption(String id) =>
          PandalDetailsScreen.addressCaption(repository.byId(id)!);
      const areaHint =
          'Map pin shows the area. Use the address to find the venue.';
      const checkHint =
          'Venue as listed by the organisers. Please check before you travel.';

      expect(
        caption('karnavati-bangiya-parishad'),
        'Listed venues: N.K. Farm, Thaltej or Govardhan Party Plot, '
        'Thaltej.\n$areaHint',
      );
      expect(caption('mukhi-party-plot'), '$checkHint\n$areaHint');
      expect(caption('ahmedabad-kalibari'), checkHint);
      expect(caption('naroda-kalibari'), areaHint);
      expect(caption('airports-authority-community-hall'), isNull);

      final hidden = RegExp(
        r'verif|need(s)? (to )?check|updated location|brst|poster',
        caseSensitive: false,
      );
      for (final pandal in repository.pandals) {
        final text = PandalDetailsScreen.addressCaption(pandal);
        if (text == null) continue;
        expect(text, isNot(contains(hidden)), reason: pandal.id);
      }
    });
  });

  test('only timings printed on the poster are filled in', () {
    final withTimings = repository.pandals.where((p) => p.timings != null);
    expect(withTimings.map((p) => p.id), ['chatterjee-barir-pujo']);
    expect(withTimings.single.timings, contains('Aarti'));

    // Only the poster's own hours become a schedule.
    final withSchedule = repository.pandals.where((p) => p.schedule != null);
    expect(withSchedule.map((p) => p.id), ['chatterjee-barir-pujo']);
  });

  group('About Pandal descriptions', () {
    const researched = {
      'chandkheda-bengal-cultural-association',
      'adani-shantigram',
      'karnavati-bangiya-parishad',
      'ahmedabad-kalibari',
    };

    test('every pandal has a unique description of 50–90 words', () {
      final descriptions = [
        for (final pandal in repository.pandals) pandal.description,
      ];
      expect(descriptions, hasLength(25));
      expect(descriptions.toSet(), hasLength(25));
      for (final (index, description) in descriptions.indexed) {
        final id = repository.pandals[index].id;
        expect(description, isNotNull, reason: id);
        final words = description!.split(RegExp(r'\s+')).length;
        expect(words, inInclusiveRange(50, 90), reason: id);
      }
    });

    test('never surface hidden poster cautions or status wording', () {
      final hidden = RegExp(
        r'verif|need(s)? check|unclear|BRTS|Jagatpur',
        caseSensitive: false,
      );
      for (final pandal in repository.pandals) {
        expect(pandal.description, isNot(contains(hidden)), reason: pandal.id);
      }
    });

    test('keep their sources beside, not inside, the text', () {
      for (final record in records) {
        final id = record['id'];
        final sources = record['descriptionSources'] as List;
        if (researched.contains(id)) {
          expect(record['descriptionBasis'], 'published-sources');
          expect(sources, isNotEmpty, reason: '$id');
          for (final source in sources.cast<Map<String, Object?>>()) {
            expect(source['url'], startsWith('https://'), reason: '$id');
            expect(source['usedFor'], isNotEmpty, reason: '$id');
          }
        } else {
          expect(record['descriptionBasis'], 'poster', reason: '$id');
          expect(sources, isEmpty, reason: '$id');
        }
        expect(record['description'], isNot(contains('http')));
      }
    });

    test('date researched details rather than presenting them as 2026', () {
      for (final id in researched) {
        final text = repository.byId(id)!.description!;
        expect(text, contains(RegExp(r'past years|recent years|20(23|24)')));
        expect(text, contains('not been announced'), reason: id);
      }
    });

    test('Chatterjee Barir Pujo is described as a private home', () {
      final text = repository.byId('chatterjee-barir-pujo')!.description!;
      expect(text, contains('private home'));
      expect(text, contains('printed darshan hours'));
    });
  });

  group('visiting hours', () {
    test('pandals without hours get only a tentative midnight cutoff', () {
      for (final record in records) {
        if (record['id'] == 'chatterjee-barir-pujo') continue;
        // Unknown actual hours stay unknown in the data.
        expect(record['timings'], isNull, reason: '${record['id']}');
        expect(record['schedule'], isNull, reason: '${record['id']}');
        expect(record['planningCutoff'], {
          'time': '00:00',
          'status': 'tentative',
        }, reason: '${record['id']}');
      }
      final tentative = repository.pandals.where(
        (p) => p.planningCutoff != null,
      );
      expect(tentative, hasLength(24));
      for (final pandal in tentative) {
        expect(pandal.planningCutoff!.isMidnight, isTrue);
        expect(pandal.schedule, isNull);
      }
    });

    test('Chatterjee Barir Pujo keeps the poster schedule', () {
      final record = records.firstWhere(
        (r) => r['id'] == 'chatterjee-barir-pujo',
      );
      expect(
        record['timings'],
        'Morning 9 to 12.30 and Evening 6 to 9 pm · Aarti (evening) 8 pm',
      );
      expect(record['planningCutoff'], isNull);

      final pandal = repository.byId('chatterjee-barir-pujo')!;
      final schedule = pandal.schedule!;
      expect(pandal.planningCutoff, isNull);
      expect(schedule.source, ScheduleSource.poster);
      expect(
        [
          for (final s in schedule.sessions)
            '${s.label}: ${s.start.format()}–${s.end.format()}',
        ],
        [
          'Morning visiting: 9:00 AM–12:30 PM',
          'Evening visiting: 6:00 PM–9:00 PM',
        ],
      );
      expect(
        [for (final e in schedule.events) '${e.label}: ${e.time.format()}'],
        ['Evening Aarti: 8:00 PM'],
      );
    });
  });

  test('unknown photos stay null', () {
    for (final pandal in repository.pandals) {
      expect(pandal.imageAsset, isNull, reason: pandal.id);
      expect(pandal.address, isNotNull, reason: pandal.id);
    }
  });

  test('pandals outside Ahmedabad keep their own town', () {
    expect(repository.pandals.map((p) => p.city).toSet(), {
      'Ahmedabad',
      'Gandhinagar',
      'Bavla',
      'Sanand',
    });
  });

  test('loads through the Flutter asset bundle', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loaded = await PandalRepository.loadFromAssets();
    expect(
      loaded.pandals.map((p) => p.id),
      repository.pandals.map((p) => p.id),
    );
  });
}
