import 'dart:convert';
import 'dart:io';

import 'package:durga_darshan/data/pandal_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/src/cli.dart';
import '../tool/src/data_file.dart';
import '../tool/src/records.dart';
import 'helpers/test_data.dart';

/// [posterDocument] with poster flags on #5, #15 and #17, like the ones the
/// earlier 2026 list carried. The final list flags no entry, so the flag
/// handling is tested on these.
JsonMap flaggedDocument() {
  final document = posterDocument();
  void flag(int n, String status, List<String> cautions) {
    final record = pandalsOf(document)
        .firstWhere((r) => r['posterNumber'] == n);
    record['verificationStatus'] = status;
    record['posterCautions'] = cautions;
  }

  flag(5, statusNeedsCheck, ['The poster marks this entry "(Need to check)".']);
  flag(15, statusConflicting, ['The poster lists two addresses.']);
  flag(17, statusConflicting, [
    'The poster gives two possible venues.',
    'The poster marks this entry "(Need to confirm location)".',
  ]);
  return document;
}

/// Feeds scripted answers and records everything printed.
class ScriptedConsole implements Console {
  ScriptedConsole([List<String> inputs = const []]) : _inputs = [...inputs];

  final List<String> _inputs;
  final _output = StringBuffer();

  String get output => _output.toString();

  @override
  String? readLine() => _inputs.isEmpty ? null : _inputs.removeAt(0);

  @override
  void write(String text) => _output.write(text);

  @override
  void writeln([String text = '']) => _output.writeln(text);
}

// Synthetic coordinates for exercising the tool; not real pandal locations.
const _lat = '23.0225';
const _lng = '72.5714';

void main() {
  group('coordinate input', () {
    test('accepts decimal degrees with at least four decimal places', () {
      expect(parseLatitude('23.0225'), 23.0225);
      expect(parseLatitude(' +23.022500 '), 23.0225);
      expect(parseLatitude('-33.8688'), -33.8688);
      expect(parseLatitude('23.02251234'), 23.022512);
      expect(parseLongitude('72.5714'), 72.5714);
      expect(parseLongitude('180.0000'), 180.0);
      expect(parseLongitude('-180.0000'), -180.0);
    });

    test('rejects malformed input', () {
      const malformed = [
        '',
        '   ',
        'abc',
        '23,0225',
        '23.0225°',
        '23.0225 N',
        'N23.0225',
        '2.30225e1',
        '0x17',
        'NaN',
        'Infinity',
        '1234.5678',
        '23.02.25',
      ];
      for (final input in malformed) {
        expect(
          () => parseLatitude(input),
          throwsA(isA<InputException>()),
          reason: input,
        );
      }
    });

    test('rejects coarse values that cannot pin a venue', () {
      for (final input in ['23', '23.', '23.0', '23.022']) {
        expect(
          () => parseLatitude(input),
          throwsA(isA<InputException>()),
          reason: input,
        );
      }
    });

    test('rejects values outside the valid ranges', () {
      for (final input in ['90.0001', '-90.0001', '123.4567']) {
        expect(
          () => parseLatitude(input),
          throwsA(
            isA<InputException>().having(
              (e) => e.message,
              'message',
              contains('between -90 and 90'),
            ),
          ),
          reason: input,
        );
      }
      for (final input in ['180.0001', '-180.0001']) {
        expect(
          () => parseLongitude(input),
          throwsA(isA<InputException>()),
          reason: input,
        );
      }
    });

    test('parses a pasted "latitude, longitude" pair', () {
      expect(parseCoordinatePair('23.0225, 72.5714'), (
        latitude: 23.0225,
        longitude: 72.5714,
      ));
      for (final input in ['23.0225 72.5714', '1.0000,2.0000,3.0000']) {
        expect(
          () => parseCoordinatePair(input),
          throwsA(isA<InputException>()),
          reason: input,
        );
      }
    });

    test('warns about far-away and swapped coordinates', () {
      expect(locationWarnings(23.0225, 72.5714), isEmpty);
      expect(locationWarnings(22.8365, 72.1897), isEmpty); // ~40 km out

      final far = locationWarnings(28.6139, 77.2090);
      expect(far, hasLength(1));
      expect(far.single, contains('km from Ahmedabad'));

      final swapped = locationWarnings(72.5714, 23.0225);
      expect(swapped, hasLength(2));
      expect(swapped.last, contains('longitude first'));
    });
  });

  group('record updates', () {
    late JsonMap flagged;

    setUp(() {
      flagged = pandalsOf(flaggedDocument())
          .firstWhere((r) => r['posterNumber'] == 5);
    });

    JsonMap candidate(JsonMap record) => withCandidate(
      record,
      latitude: 23.0225,
      longitude: 72.5714,
      source: 'test source',
      recordedOn: '2026-10-14',
    );

    test('a candidate keeps its status, notes and other fields', () {
      final updated = candidate(flagged);

      expect(updated['verificationStatus'], statusNeedsCheck);
      expect(locationStateOf(updated), LocationState.candidate);
      expect(updated['notes'], flagged['notes']);
      for (final key in flagged.keys) {
        if (const ['latitude', 'longitude'].contains(key)) continue;
        expect(updated[key], flagged[key], reason: key);
      }
      // The new details sit right after the status.
      final keys = updated.keys.toList();
      expect(
        keys.indexOf('verification'),
        keys.indexOf('verificationStatus') + 1,
      );
      expect(verificationOf(updated)['coordinatesSource'], 'test source');
      expect(flagged['latitude'], isNull, reason: 'input left untouched');
    });

    test('verifying remembers the poster status', () {
      final verified = withVerified(
        candidate(flagged),
        note: 'confirmed',
        verifiedOn: '2026-10-15',
      );

      expect(verified['verificationStatus'], statusVerified);
      expect(locationStateOf(verified), LocationState.verified);
      expect(verificationOf(verified), {
        'coordinatesSource': 'test source',
        'coordinatesRecordedOn': '2026-10-14',
        'coordinatesPrecision': null,
        'verifiedOn': '2026-10-15',
        'verificationNote': 'confirmed',
        'statusBeforeVerification': statusNeedsCheck,
      });
      expect(originalStatusOf(verified), statusNeedsCheck);
      expect(verified['notes'], flagged['notes']);
    });

    test('only candidates can be verified', () {
      expect(
        () => withVerified(flagged, note: 'n', verifiedOn: '2026-10-15'),
        throwsStateError,
      );
    });

    test('new coordinates for a verified pandal make it a candidate again', () {
      final verified = withVerified(
        candidate(flagged),
        note: 'confirmed',
        verifiedOn: '2026-10-15',
      );
      final replaced = candidate(verified);

      expect(replaced['verificationStatus'], statusNeedsCheck);
      expect(locationStateOf(replaced), LocationState.candidate);
      expect(verificationOf(replaced)['verifiedOn'], isNull);
      expect(verificationOf(replaced)['statusBeforeVerification'], isNull);
    });

    test('clearing removes coordinates and restores the poster status', () {
      final cleared = withoutLocation(
        withVerified(candidate(flagged), note: 'n', verifiedOn: '2026-10-15'),
      );

      expect(cleared['latitude'], isNull);
      expect(cleared['longitude'], isNull);
      expect(cleared['verification'], isNull);
      expect(cleared['verificationStatus'], statusNeedsCheck);
      expect(locationStateOf(cleared), LocationState.unresolved);
    });
  });

  group('validateDocument', () {
    JsonMap documentWith(JsonMap Function(JsonMap) change) {
      final document = posterDocument();
      final pandals = pandalsOf(document);
      pandals[0] = change({...pandals[0]});
      return document;
    }

    test('accepts the poster data', () {
      expect(validateDocument(posterDocument()), isEmpty);
    });

    test('reports integrity problems', () {
      final cases = <String, JsonMap>{
        'marked verified but has no valid coordinates': documentWith(
          (r) => r..['verificationStatus'] = statusVerified,
        ),
        'no recorded source': documentWith(
          (r) => r
            ..['latitude'] = 23.0225
            ..['longitude'] = 72.5714,
        ),
        'both be set or both be null': documentWith(
          (r) => r..['latitude'] = 23.0225,
        ),
        'between -90 and 90': documentWith(
          (r) => r
            ..['latitude'] = 123.0
            ..['longitude'] = 72.5
            ..['verification'] = {'coordinatesSource': 'x'},
        ),
        'unknown verificationStatus': documentWith(
          (r) => r..['verificationStatus'] = 'probably',
        ),
        'used more than once': documentWith((r) => r..['posterNumber'] = 2),
        'must not have a "planningCutoff"': documentWith(
          (r) => r
            ..['schedule'] = {
              'source': 'poster',
              'events': [
                {'label': 'Aarti', 'time': '20:00'},
              ],
            },
        ),
        '"schedule" is invalid': documentWith(
          (r) => r
            ..['planningCutoff'] = null
            ..['schedule'] = {'source': 'rumour', 'sessions': <Object?>[]},
        ),
        '"planningCutoff" must be null or': documentWith(
          (r) => r..['planningCutoff'] = {'time': '24:00', 'status': 'final'},
        ),
        'unknown descriptionBasis': documentWith(
          (r) => r..['descriptionBasis'] = 'hearsay',
        ),
        'based on published sources but lists none': documentWith(
          (r) => r
            ..['descriptionBasis'] = 'published-sources'
            ..['descriptionSources'] = <Object?>[],
        ),
        'with a title and url': documentWith(
          (r) => r
            ..['descriptionSources'] = [
              {'title': 'No link'},
            ],
        ),
        '"name" must be a non-empty string': documentWith(
          (r) => r..['name'] = '',
        ),
      };
      cases.forEach((expected, document) {
        expect(
          validateDocument(document).join('\n'),
          contains(expected),
          reason: expected,
        );
      });
    });
  });

  group('command line', () {
    late Directory dir;
    late String path;
    late String original;
    final today = DateTime(2026, 10, 14, 9, 30);

    setUp(() {
      dir = Directory.systemTemp.createTempSync('pandal_verification_');
      path = '${dir.path}${Platform.pathSeparator}pandals.json';
      original = encodeDocument(flaggedDocument());
      File(path).writeAsStringSync(original);
    });

    tearDown(() => dir.deleteSync(recursive: true));

    ({int code, String output}) run(
      List<String> args, [
      List<String> inputs = const [],
    ]) {
      final console = ScriptedConsole(inputs);
      final code = runVerificationCli(
        [...args, '--file', path],
        console: console,
        now: () => today,
      );
      return (code: code, output: console.output);
    }

    String contents() => File(path).readAsStringSync();
    JsonMap document() => jsonDecode(contents()) as JsonMap;
    JsonMap record(int n) =>
        pandalsOf(document()).firstWhere((r) => r['posterNumber'] == n);
    List<FileSystemEntity> backups() {
      final backupDir = Directory(
        '${dir.path}${Platform.pathSeparator}backups',
      );
      return backupDir.existsSync() ? backupDir.listSync() : const [];
    }

    PandalRepository app() => PandalRepository.fromJsonString(contents());

    void expectUnchanged() {
      expect(contents(), original);
      expect(backups(), isEmpty);
    }

    void recordCandidate(int n) {
      final result = run(['set', '$n'], [_lat, _lng, 'Test source', 'yes']);
      expect(result.code, exitOk, reason: result.output);
    }

    test('list shows every pandal with its details', () {
      final result = run(['list']);

      expect(result.code, exitOk);
      for (var n = 1; n <= 24; n++) {
        expect(result.output, contains('#${'$n'.padLeft(2, '0')}  '));
      }
      expect(result.output, contains('All Gujarat Resurgent Trust'));
      expect(result.output, contains('needs check'));
      expect(result.output, contains('unclear location'));
      expect(result.output, contains('(Need to check)'));
      expect(result.output, contains('Adani Shantigram Township'));
      expect(result.output, contains('Coordinates  none'));
    });

    test('set records a candidate without verifying it', () {
      final result = run(['set', '5'], [_lat, _lng, 'Checked on site', 'yes']);

      expect(result.code, exitOk, reason: result.output);
      final updated = record(5);
      expect(updated['latitude'], 23.0225);
      expect(updated['longitude'], 72.5714);
      expect(updated['verificationStatus'], statusNeedsCheck);
      expect(verificationOf(updated)['coordinatesSource'], 'Checked on site');
      expect(verificationOf(updated)['coordinatesRecordedOn'], '2026-10-14');
      expect(result.output, contains('verify 5'));

      // The app does not pin candidates.
      expect(app().mappable, isEmpty);
    });

    test('set changes nothing but the chosen pandal', () {
      final before = jsonDecode(original) as JsonMap;
      recordCandidate(5);
      final after = document();

      for (final key in before.keys) {
        if (key != 'pandals') expect(after[key], before[key], reason: key);
      }
      final beforePandals = pandalsOf(before);
      final afterPandals = pandalsOf(after);
      for (var i = 0; i < beforePandals.length; i++) {
        final beforeRecord = beforePandals[i];
        if (beforeRecord['posterNumber'] == 5) {
          for (final key in beforeRecord.keys) {
            if (const ['latitude', 'longitude'].contains(key)) continue;
            expect(afterPandals[i][key], beforeRecord[key], reason: key);
          }
        } else {
          expect(afterPandals[i], beforeRecord);
        }
      }
    });

    test('saves are backed up and atomic', () {
      recordCandidate(5);

      final saved = backups();
      expect(saved, hasLength(1));
      expect(saved.single.path, endsWith('pandals-20261014-093000.json'));
      expect(File(saved.single.path).readAsStringSync(), original);
      expect(
        dir.listSync().where((f) => f.path.endsWith('.tmp')),
        isEmpty,
        reason: 'no temporary files are left behind',
      );
    });

    test('set asks again after malformed input', () {
      final result = run(
        ['set', '5'],
        ['abc', '23.02', _lat, '72.5714 E', _lng, 'Test source', 'yes'],
      );

      expect(result.code, exitOk, reason: result.output);
      expect(result.output, contains('decimal degrees'));
      expect(result.output, contains('at least 4 decimal places'));
      expect(record(5)['latitude'], 23.0225);
    });

    test('set accepts a pasted coordinate pair', () {
      final result = run(['set', '5'], ['$_lat, $_lng', 'Test source', 'yes']);

      expect(result.code, exitOk, reason: result.output);
      expect(record(5)['longitude'], 72.5714);
    });

    test('set can be cancelled at every step', () {
      for (final inputs in [
        <String>[],
        [''],
        [_lat, ''],
        [_lat, _lng, ''],
        [_lat, _lng, 'Test source', 'no'],
        [_lat, _lng, 'Test source', 'y'],
      ]) {
        final result = run(['set', '5'], inputs);
        expect(result.code, exitOk, reason: '$inputs');
        expect(result.output, contains('No changes made.'), reason: '$inputs');
        expectUnchanged();
      }
    });

    test('set warns about far-away coordinates', () {
      final result = run(['set', '5'], ['28.6139', '77.2090', 'no']);

      expect(result.output, contains('km from Ahmedabad'));
      expectUnchanged();
    });

    test('set will not replace existing coordinates without confirmation', () {
      recordCandidate(5);
      final saved = contents();

      final declined = run(['set', '5'], ['no']);
      expect(declined.output, contains('already has candidate coordinates'));
      expect(contents(), saved);

      final replaced = run(
        ['set', '5'],
        ['yes', '23.0300', '72.5800', 'Second source', 'yes'],
      );
      expect(replaced.code, exitOk, reason: replaced.output);
      expect(record(5)['latitude'], 23.03);
      expect(verificationOf(record(5))['coordinatesSource'], 'Second source');
    });

    test('verify needs candidate coordinates first', () {
      final result = run(['verify', '5'], ['yes']);

      expect(result.code, exitError);
      expect(result.output, contains('set 5'));
      expectUnchanged();
    });

    test('verify marks a candidate verified only after every confirmation', () {
      recordCandidate(5);
      final result = run(
        ['verify', '5'],
        ['yes', 'yes', 'yes', 'Organiser confirmed by phone', '5'],
      );

      expect(result.code, exitOk, reason: result.output);
      expect(result.output, contains('flagged this pandal as "needs check"'));
      final verified = record(5);
      expect(verified['verificationStatus'], statusVerified);
      expect(verificationOf(verified)['verifiedOn'], '2026-10-14');
      expect(
        verificationOf(verified)['verificationNote'],
        'Organiser confirmed by phone',
      );
      expect(
        verificationOf(verified)['statusBeforeVerification'],
        statusNeedsCheck,
      );
      // Poster notes and cautions are never touched.
      final before = pandalsOf(jsonDecode(original) as JsonMap)
          .firstWhere((r) => r['posterNumber'] == 5);
      expect(verified['notes'], before['notes']);
      expect(verified['posterCautions'], before['posterCautions']);
      expect(verified['posterCautions'] ?? verified['notes'], [
        'The poster marks this entry "(Need to check)".',
      ]);

      // Now, and only now, the app pins it.
      expect(app().mappable.map((p) => p.posterNumber), [5]);
    });

    test('verify changes nothing unless every answer confirms', () {
      recordCandidate(5);
      final candidate = contents();

      for (final inputs in [
        ['no'],
        ['yes', 'no'],
        ['yes', 'yes', 'no'],
        ['yes', 'yes', 'yes', ''],
        ['yes', 'yes', 'yes', 'Confirmed', '4'],
        ['yes', 'yes', 'yes', 'Confirmed'],
      ]) {
        final result = run(['verify', '5'], inputs);
        expect(result.output, contains('Not verified'), reason: '$inputs');
        expect(contents(), candidate, reason: '$inputs');
      }
      expect(app().mappable, isEmpty);
    });

    test('verify only asks about poster flags when there is one', () {
      recordCandidate(1);
      final result = run(['verify', '1'], ['yes', 'yes', 'Visited', '1']);

      expect(result.code, exitOk, reason: result.output);
      expect(result.output, isNot(contains('flagged')));
      expect(record(1)['verificationStatus'], statusVerified);
    });

    test('replacing verified coordinates removes the verification', () {
      recordCandidate(15);
      run(['verify', '15'], ['yes', 'yes', 'yes', 'Visited', '15']);
      expect(record(15)['verificationStatus'], statusVerified);

      final result = run(
        ['set', '15'],
        ['yes', '23.0300', '72.5800', 'Corrected', 'yes'],
      );

      expect(result.output, contains('removes its verified status'));
      expect(record(15)['verificationStatus'], statusConflicting);
      expect(verificationOf(record(15))['verifiedOn'], isNull);
      expect(app().mappable, isEmpty);
    });

    test('clear removes coordinates after confirmation', () {
      recordCandidate(17);
      run(['verify', '17'], ['yes', 'yes', 'yes', 'Visited', '17']);

      final declined = run(['clear', '17'], ['no']);
      expect(declined.output, contains('No changes made.'));
      expect(record(17)['verificationStatus'], statusVerified);

      final result = run(['clear', '17'], ['yes']);
      expect(result.code, exitOk, reason: result.output);
      final cleared = record(17);
      expect(cleared['latitude'], isNull);
      expect(cleared['verification'], isNull);
      expect(cleared['verificationStatus'], statusConflicting);
      expect(cleared['posterCautions'] ?? cleared['notes'], hasLength(2));
    });

    test('review groups verified, candidate and unresolved pandals', () {
      recordCandidate(1);
      recordCandidate(5);
      run(['verify', '5'], ['yes', 'yes', 'yes', 'Visited', '5']);

      final result = run(['review']);
      expect(result.code, exitOk);
      expect(result.output, contains('VERIFIED (1)'));
      expect(result.output, contains('CANDIDATES (1)'));
      expect(result.output, contains('UNRESOLVED (22)'));
      expect(result.output, contains('poster flag: needs check'));
      expect(
        result.output,
        contains('1 verified · 1 candidate(s) · 22 unresolved'),
      );
    });

    test('refuses to work on an invalid file', () {
      final broken = posterDocument();
      pandalsOf(broken)[0]['verificationStatus'] = statusVerified;
      final brokenText = encodeDocument(broken);
      File(path).writeAsStringSync(brokenText);

      for (final args in [
        ['review'],
        ['set', '1'],
      ]) {
        final result = run(args, [_lat, _lng, 'Test source', 'yes']);
        expect(result.code, exitError, reason: '$args');
        expect(result.output, contains('marked verified but has no valid'));
      }
      expect(contents(), brokenText);
    });

    test('will not overwrite changes made after loading', () {
      final dataFile = PandalDataFile(path);
      final loaded = dataFile.load();
      final edited = '$original\n';
      File(path).writeAsStringSync(edited);

      expect(
        () => dataFile.save(loaded, loaded.document),
        throwsA(isA<DataFileException>()),
      );
      expect(contents(), edited);
      expect(backups(), isEmpty);
    });

    test('reports usage mistakes', () {
      expect(run([]).code, exitUsage);
      expect(run(['help']).code, exitOk);
      expect(run(['set']).code, exitUsage);
      expect(run(['set', 'five']).code, exitUsage);
      expect(run(['geocode', '5']).code, exitUsage);
      expect(run(['list', '--force']).code, exitUsage);

      final missing = run(['show', '99']);
      expect(missing.code, exitError);
      expect(missing.output, contains('No pandal has poster number 99'));
      expectUnchanged();
    });
  });
}
