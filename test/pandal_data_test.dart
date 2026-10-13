import 'dart:convert';
import 'dart:io';

import 'package:durga_darshan/data/pandal_repository.dart';
import 'package:durga_darshan/models/coordinates.dart';
import 'package:durga_darshan/models/pandal.dart';
import 'package:durga_darshan/models/visiting_hours.dart';
import 'package:durga_darshan/screens/pandal_details_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/src/records.dart' as tool;

/// Checks the bundled data transcribed from the final 2026 list. These rules
/// hold however many locations have been verified since.
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

  test('contains all 24 pandals of the final list with unique ids', () {
    final pandals = repository.pandals;
    expect(pandals, hasLength(24));

    final ids = pandals.map((p) => p.id).toList();
    expect(ids.toSet(), hasLength(24));
    for (final id in ids) {
      expect(id, matches(RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$')), reason: id);
    }

    expect(pandals.map((p) => p.posterNumber), [
      for (var n = 1; n <= 24; n++) n,
    ]);
  });

  test('pandals carried over from the earlier list keep their ids', () {
    // Saved favourites and visits refer to these ids.
    const carriedOver = {
      'airports-authority-community-hall': 16,
      'naroda-kalibari': 5,
      'payal-upvan-party-plot': 11,
      'vaibhav-hall': 10,
      'bengal-youth-cultural-association': 19,
      'adinath-nagar-indrapark-society': 15,
      'adinath-nagar-jadeshwar-mahadev-mandir': 14,
      'kankaria-open-air-theater': 9,
      'railway-colony-ground-sabarmati': 3,
      'chandkheda-bengal-cultural-association': 12,
      'adani-shantigram': 8,
      'savvy-swaraj-durgotsav': 7,
      'sola': 18,
      'karnavati-bangiya-parishad': 4,
      'ahmedabad-kalibari': 2,
      'shantaram-community-hall': 17,
      'chatterjee-barir-pujo': 13,
      'gandhinagar-sector-22': 20,
      'shakti-dwar-charitable-trust': 21,
      'bavla-durga-puja-association': 6,
      'sanand-durga-puja': 24,
    };
    carriedOver.forEach((id, number) {
      expect(repository.byId(id)?.posterNumber, number, reason: id);
    });
    for (final dropped in [
      'ramkrishna-seva-kendra',
      'mukhi-party-plot',
      'palkhi-upvan-party-plot',
      'durga-ground-vatva',
    ]) {
      expect(repository.byId(dropped), isNull, reason: dropped);
    }
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

  test('the final list flags no entry and gives one venue for each', () {
    for (final record in records) {
      final id = record['id'];
      expect(tool.originalStatusOf(record), 'unverified', reason: '$id');
      expect(record['posterCautions'], isNull, reason: '$id');
      expect(record['posterAddress'], isNull, reason: '$id');
    }
  });

  test('corrections to the printed list are explained in the data', () {
    final corrected = {
      for (final record in records)
        if (record['transcriptionNotes'] case final List notes)
          record['id']: notes,
    };
    expect(corrected.keys, [
      'bavla-durga-puja-association',
      'adani-shantigram',
      'vaibhav-hall',
      'adinath-nagar-jadeshwar-mahadev-mandir',
      'adinath-nagar-indrapark-society',
      'bangiyo-antariksha-sanskriti-samiti',
      'sanand-durga-puja',
    ]);
    for (final notes in corrected.values) {
      expect(notes, everyElement(isNotEmpty));
    }
    // The list prints Sanand twice; it is listed once.
    expect(repository.pandals.where((p) => p.area == 'Sanand'), hasLength(1));
    // Notes on the transcription stay out of the app.
    for (final pandal in repository.pandals) {
      expect(pandal.notes.join(), isNot(contains('final list')));
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
      expect(areaIds, hasLength(19));
      expect(
        repository.pandals.where((p) => p.pinShowsAreaOnly).map((p) => p.id),
        areaIds,
      );
    });

    test('no entry asks visitors to check its venue', () {
      expect(repository.pandals.where((p) => p.venueNeedsChecking), isEmpty);
      expect(
        repository.pandals.where((p) => p.listedVenues.isNotEmpty),
        isEmpty,
      );
    });

    test('address captions use friendly wording, not poster cautions', () {
      String? caption(String id) =>
          PandalDetailsScreen.addressCaption(repository.byId(id)!);
      const areaHint =
          'Map pin shows the area. Use the address to find the venue.';
      const checkHint =
          'Venue as listed by the organisers. Please check before you travel.';

      expect(caption('karnavati-bangiya-parishad'), areaHint);
      expect(caption('naroda-kalibari'), areaHint);
      expect(caption('ahmedabad-kalibari'), isNull);
      expect(caption('vaibhav-hall'), isNull);

      // Entries the list doubts, or gives two venues for, still get a hint.
      String? hint({
        List<String> listedVenues = const [],
        bool venueNeedsChecking = false,
      }) => PandalDetailsScreen.addressCaption(
        Pandal(
          id: 'p',
          name: 'P',
          area: 'A',
          city: 'C',
          latitude: 23.03,
          longitude: 72.58,
          verificationStatus: VerificationStatus.verified,
          pinPrecision: PinPrecision.area,
          listedVenues: listedVenues,
          venueNeedsChecking: venueNeedsChecking,
        ),
      );
      expect(hint(), areaHint);
      expect(hint(venueNeedsChecking: true), '$checkHint\n$areaHint');
      expect(
        hint(listedVenues: ['First Hall', 'Second Ground']),
        'Listed venues: First Hall or Second Ground.\n$areaHint',
      );

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
      expect(descriptions, hasLength(24));
      expect(descriptions.toSet(), hasLength(24));
      for (final (index, description) in descriptions.indexed) {
        final id = repository.pandals[index].id;
        expect(description, isNotNull, reason: id);
        final words = description!.split(RegExp(r'\s+')).length;
        expect(words, inInclusiveRange(50, 90), reason: id);
      }
    });

    test('never surface hidden poster cautions or status wording', () {
      final hidden = RegExp(
        r'verif|need(s)? check|unclear|BRTS',
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
      expect(tentative, hasLength(23));
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
