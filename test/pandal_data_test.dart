import 'dart:convert';
import 'dart:io';

import 'package:durga_darshan/data/pandal_repository.dart';
import 'package:durga_darshan/models/coordinates.dart';
import 'package:durga_darshan/models/pandal.dart';
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

  test('only timings printed on the poster are filled in', () {
    final withTimings = repository.pandals.where((p) => p.timings != null);
    expect(withTimings.map((p) => p.id), ['chatterjee-barir-pujo']);
    expect(withTimings.single.timings, contains('Aarti'));
  });

  test('unknown descriptions and photos stay null', () {
    for (final pandal in repository.pandals) {
      expect(pandal.description, isNull, reason: pandal.id);
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
