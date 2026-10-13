import 'dart:io';

import 'data_file.dart';
import 'records.dart';

const defaultDataPath = 'assets/data/pandals.json';

const exitOk = 0;
const exitError = 1;
const exitUsage = 64;

const usage = '''
Durga Darshan: pandal location verification (developer tool, local only)

Usage:
  dart run tool/verify_pandals.dart <command> [poster-number] [--file <path>]

Commands:
  list          Every pandal with its status, notes and coordinates.
  show <n>      One pandal in full, with a map link for checking.
  set <n>       Record candidate coordinates. Candidates stay hidden in the app.
  verify <n>    Mark a candidate verified, after you have independently
                confirmed the venue and the current event location.
  clear <n>     Remove a pandal's coordinates and any verification.
  review        Verified, candidate and unresolved pandals at a glance.
  help          Show this message.

<n> is the pandal's number on the poster (1-24).
Default file: $defaultDataPath (run from the project root).''';

/// Line-based input and output, so tests can script a session.
abstract interface class Console {
  /// The next line of input, or null at end of input.
  String? readLine();

  void write(String text);

  void writeln([String text = '']);
}

class StdioConsole implements Console {
  const StdioConsole();

  @override
  String? readLine() => stdin.readLineSync();

  @override
  void write(String text) => stdout.write(text);

  @override
  void writeln([String text = '']) => stdout.writeln(text);
}

/// Runs one command and returns the process exit code.
int runVerificationCli(
  List<String> args, {
  Console console = const StdioConsole(),
  DateTime Function()? now,
}) {
  final positional = <String>[];
  var path = defaultDataPath;
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--file') {
      if (i + 1 >= args.length) {
        return _usageError(console, '--file needs a path.');
      }
      path = args[++i];
    } else if (arg.startsWith('--file=')) {
      path = arg.substring('--file='.length);
    } else if (arg.startsWith('-') && !const ['-h', '--help'].contains(arg)) {
      return _usageError(console, 'Unknown option $arg.');
    } else {
      positional.add(arg);
    }
  }

  final command = positional.isEmpty ? null : positional.first;
  if (command == null || const ['help', '-h', '--help'].contains(command)) {
    console.writeln(usage);
    return command == null ? exitUsage : exitOk;
  }

  final session = _Session(
    console,
    PandalDataFile(path, now: now),
    now ?? DateTime.now,
  );
  try {
    switch (command) {
      case 'list':
        return session.list();
      case 'review':
        return session.review();
      case 'show' || 'set' || 'verify' || 'clear':
        if (positional.length != 2) {
          return _usageError(console, '`$command` needs one poster number.');
        }
        final number = int.tryParse(positional[1].replaceFirst('#', ''));
        if (number == null) {
          return _usageError(console, '"${positional[1]}" is not a number.');
        }
        return switch (command) {
          'show' => session.show(number),
          'set' => session.set(number),
          'verify' => session.verify(number),
          _ => session.clear(number),
        };
      default:
        return _usageError(console, 'Unknown command "$command".');
    }
  } on DataFileException catch (error) {
    console.writeln('Error: $error');
    return exitError;
  } on FileSystemException catch (error) {
    console.writeln('Error: could not read or write $path: ${error.message}');
    return exitError;
  }
}

int _usageError(Console console, String message) {
  console
    ..writeln('Error: $message')
    ..writeln()
    ..writeln(usage);
  return exitUsage;
}

class _Session {
  _Session(this.console, this.dataFile, this.now);

  final Console console;
  final PandalDataFile dataFile;
  final DateTime Function() now;

  static const _cancelled = 'No changes made.';

  // -------------------------------------------------------------------------
  // Read-only commands

  int list() {
    final loaded = dataFile.load();
    final pandals = pandalsOf(loaded.document);
    console.writeln('${pandals.length} pandals in ${dataFile.path}');
    for (final record in pandals) {
      console.writeln();
      _describe(record);
    }
    return exitOk;
  }

  int show(int number) {
    final loaded = dataFile.load();
    final index = indexOfPosterNumber(loaded.document, number);
    if (index == null) return _notFound(number);
    final record = pandalsOf(loaded.document)[index];
    _describe(record);
    final lat = latitudeOf(record);
    final lng = longitudeOf(record);
    if (lat != null && lng != null && hasCoordinates(record)) {
      console.writeln('     Check on map: ${openStreetMapLink(lat, lng)}');
    }
    return exitOk;
  }

  int review() {
    final loaded = dataFile.load();
    final groups = {
      for (final state in LocationState.values) state: <JsonMap>[],
    };
    for (final record in pandalsOf(loaded.document)) {
      groups[locationStateOf(record)]!.add(record);
    }

    void section(
      LocationState state,
      String name,
      String description,
      String Function(JsonMap) line,
    ) {
      final records = groups[state]!;
      console
        ..writeln()
        ..writeln('$name (${records.length}): $description');
      if (records.isEmpty) console.writeln('  none');
      for (final record in records) {
        console.writeln('  ${_heading(record)}');
        console.writeln('       ${line(record)}');
      }
    }

    section(LocationState.verified, 'VERIFIED', 'shown on the app map', (r) {
      final v = verificationOf(r);
      final precision = v['coordinatesPrecision'];
      return '${_coordinates(r)} · verified ${v['verifiedOn'] ?? '(date not recorded)'}'
          '${precision == null ? '' : ' · ${precisionLabel(precision)} pin'}'
          '${_flagSuffix(originalStatusOf(r))}';
    });
    section(
      LocationState.candidate,
      'CANDIDATES',
      'awaiting your confirmation, hidden in the app',
      (r) =>
          '${_coordinates(r)} · ${statusLabel(r['verificationStatus'])}'
          ' · source: ${verificationOf(r)['coordinatesSource']}',
    );
    section(
      LocationState.unresolved,
      'UNRESOLVED',
      'no coordinates yet',
      (r) => '${r['area']} · ${statusLabel(r['verificationStatus'])}',
    );

    final counts = groups.map(
      (state, records) => MapEntry(state, records.length),
    );
    console
      ..writeln()
      ..writeln(
        'Summary: ${counts[LocationState.verified]} verified · '
        '${counts[LocationState.candidate]} candidate(s) · '
        '${counts[LocationState.unresolved]} unresolved.',
      );
    if (counts[LocationState.candidate]! > 0) {
      console.writeln(
        'Next: confirm a candidate with `dart run tool/verify_pandals.dart '
        'verify <n>`.',
      );
    } else if (counts[LocationState.unresolved]! > 0) {
      console.writeln(
        'Next: record coordinates with `dart run tool/verify_pandals.dart '
        'set <n>`.',
      );
    }
    return exitOk;
  }

  // -------------------------------------------------------------------------
  // Commands that change the file

  int set(int number) {
    final loaded = dataFile.load();
    final index = indexOfPosterNumber(loaded.document, number);
    if (index == null) return _notFound(number);
    final record = pandalsOf(loaded.document)[index];
    _describe(record);
    console.writeln();

    final state = locationStateOf(record);
    if (state != LocationState.unresolved) {
      console.writeln(
        'This pandal already has ${state == LocationState.verified ? 'VERIFIED' : 'candidate'} '
        'coordinates: ${_coordinates(record)}.',
      );
      if (state == LocationState.verified) {
        console.writeln(
          'Replacing them removes its verified status. It will not be shown '
          'on the map until you verify it again.',
        );
      }
      if (!_confirm('Replace the existing coordinates?')) return _cancel();
    }

    console.writeln(
      'Enter coordinates in decimal degrees, e.g. 23.022500 and 72.571400, '
      'or paste "latitude, longitude". Leave blank to cancel.',
    );
    final coordinates = _promptCoordinates();
    if (coordinates == null) return _cancel();
    final (:latitude, :longitude) = coordinates;

    final warnings = locationWarnings(latitude, longitude);
    if (warnings.isNotEmpty) {
      for (final warning in warnings) {
        console.writeln('Warning: $warning');
      }
      if (!_confirm('Use these coordinates anyway?')) return _cancel();
    }

    final source = _promptText(
      'Source or note (where these coordinates came from): ',
    );
    if (source == null) return _cancel();

    console
      ..writeln()
      ..writeln('#$number ${record['name']}')
      ..writeln('  Candidate: ${formatCoordinates(latitude, longitude)}')
      ..writeln('  Source:    $source')
      ..writeln(
        '  Status stays "${statusLabel(originalStatusOf(record))}". It '
        'will NOT be shown in the app until you run `verify $number`.',
      );
    if (!_confirm('Save these candidate coordinates?')) return _cancel();

    final backup = dataFile.save(
      loaded,
      replaceRecord(
        loaded.document,
        index,
        withCandidate(
          record,
          latitude: latitude,
          longitude: longitude,
          source: source,
          recordedOn: isoDate(now()),
        ),
      ),
    );
    console
      ..writeln('Saved #$number as a candidate. Backup: $backup')
      ..writeln(
        'After independently confirming the venue and the current event '
        'location, run: dart run tool/verify_pandals.dart verify $number',
      );
    return exitOk;
  }

  int verify(int number) {
    final loaded = dataFile.load();
    final index = indexOfPosterNumber(loaded.document, number);
    if (index == null) return _notFound(number);
    final record = pandalsOf(loaded.document)[index];

    switch (locationStateOf(record)) {
      case LocationState.unresolved:
        console.writeln(
          '#$number has no coordinates to verify. Record candidate '
          'coordinates first: dart run tool/verify_pandals.dart set $number',
        );
        return exitError;
      case LocationState.verified:
        console.writeln(
          '#$number is already verified '
          '(${verificationOf(record)['verifiedOn'] ?? 'date not recorded'}).',
        );
        return exitOk;
      case LocationState.candidate:
        break;
    }

    _describe(record);
    console
      ..writeln(
        '     Check on map: '
        '${openStreetMapLink(latitudeOf(record)!, longitudeOf(record)!)}',
      )
      ..writeln()
      ..writeln('Only continue if you have independently confirmed BOTH:')
      ..writeln('  1. the venue is at these coordinates, and')
      ..writeln('  2. this year\'s pujo is being held at that venue.');

    if (!_confirm('Have you confirmed the venue at these coordinates?') ||
        !_confirm('Have you confirmed this is the current event location?')) {
      return _notVerified();
    }

    final status = record['verificationStatus'] as String;
    if (flaggedStatuses.contains(status)) {
      console.writeln(
        'The source list flagged this pandal as "${statusLabel(status)}". '
        'See the notes above.',
      );
      if (!_confirm('Have you resolved that flag?')) return _notVerified();
    }

    final note = _promptText(
      'How did you confirm it? (e.g. visited on 14 Oct; organiser confirmed '
      'by phone): ',
    );
    if (note == null) return _notVerified();

    console.write('Type the poster number ($number) to mark it verified: ');
    if (console.readLine()?.trim() != '$number') return _notVerified();

    final backup = dataFile.save(
      loaded,
      replaceRecord(
        loaded.document,
        index,
        withVerified(record, note: note, verifiedOn: isoDate(now())),
      ),
    );
    console
      ..writeln('Verified #$number. Backup: $backup')
      ..writeln(
        'Fully restart the app (not hot reload) to see its pin on the map.',
      );
    return exitOk;
  }

  int clear(int number) {
    final loaded = dataFile.load();
    final index = indexOfPosterNumber(loaded.document, number);
    if (index == null) return _notFound(number);
    final record = pandalsOf(loaded.document)[index];

    final state = locationStateOf(record);
    if (state == LocationState.unresolved) {
      console.writeln('#$number has no coordinates. $_cancelled');
      return exitOk;
    }
    _describe(record);
    console.writeln();
    if (state == LocationState.verified) {
      console.writeln(
        'This removes its verified status and its pin from the map.',
      );
    }
    if (!_confirm('Remove the coordinates for #$number?')) return _cancel();

    final backup = dataFile.save(
      loaded,
      replaceRecord(loaded.document, index, withoutLocation(record)),
    );
    console.writeln('Cleared #$number. Backup: $backup');
    return exitOk;
  }

  // -------------------------------------------------------------------------
  // Prompts

  /// Only a typed "yes" counts as agreement.
  bool _confirm(String question) {
    console.write('$question Type "yes" to continue: ');
    return console.readLine()?.trim().toLowerCase() == 'yes';
  }

  /// Required free text; blank input or end of input cancels.
  String? _promptText(String prompt) {
    console.write(prompt);
    final text = console.readLine()?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  /// Asks until the input is valid. Blank input or end of input cancels.
  ({double latitude, double longitude})? _promptCoordinates() {
    double? latitude;
    while (latitude == null) {
      console.write('Latitude: ');
      final input = console.readLine()?.trim();
      if (input == null || input.isEmpty) return null;
      try {
        if (input.contains(',')) return parseCoordinatePair(input);
        latitude = parseLatitude(input);
      } on InputException catch (error) {
        console.writeln('  $error');
      }
    }
    while (true) {
      console.write('Longitude: ');
      final input = console.readLine()?.trim();
      if (input == null || input.isEmpty) return null;
      try {
        return (latitude: latitude, longitude: parseLongitude(input));
      } on InputException catch (error) {
        console.writeln('  $error');
      }
    }
  }

  // -------------------------------------------------------------------------
  // Output

  void _describe(JsonMap record) {
    final verification = verificationOf(record);
    final state = locationStateOf(record);
    final notes = (record['notes'] as List?)?.cast<String>() ?? const [];

    console.writeln(_heading(record));
    _field('Status', statusLabel(record['verificationStatus']));
    _field(
      'Area',
      record['area'] == record['city']
          ? '${record['area']}'
          : '${record['area']} · ${record['city']}',
    );
    _field('Address', '${record['address'] ?? '(not listed)'}');
    final posterAddress = record['posterAddress'];
    if (posterAddress != null && posterAddress != record['address']) {
      _field('On poster', '$posterAddress');
    }
    _field('Coordinates', switch (state) {
      LocationState.unresolved => 'none',
      LocationState.candidate =>
        '${_coordinates(record)}  (candidate, hidden in the app)',
      LocationState.verified =>
        '${_coordinates(record)}  (verified '
            '${verification['verifiedOn'] ?? '- date not recorded'})',
    });
    final precision = verification['coordinatesPrecision'];
    if (state != LocationState.unresolved && precision != null) {
      _field('Precision', '${precisionLabel(precision)} (from address lookup)');
    }
    if (state != LocationState.unresolved) {
      _field(
        'Source',
        '${verification['coordinatesSource']}'
            '${verification['coordinatesRecordedOn'] == null ? '' : ' (recorded ${verification['coordinatesRecordedOn']})'}',
      );
    }
    if (state == LocationState.verified) {
      if (verification['verificationNote'] != null) {
        _field('Confirmed', '${verification['verificationNote']}');
      }
      final before = verification['statusBeforeVerification'];
      if (before != null && before != statusUnverified) {
        _field('Poster flag', statusLabel(before));
      }
    }
    if (notes.isEmpty) {
      _field('Notes', 'none');
    } else {
      for (var i = 0; i < notes.length; i++) {
        _field(i == 0 ? 'Notes' : '', '• ${notes[i]}');
      }
    }
    final cautions =
        (record['posterCautions'] as List?)?.cast<String>() ?? const [];
    for (var i = 0; i < cautions.length; i++) {
      _field(i == 0 ? 'Cautions' : '', '• ${cautions[i]}');
    }
  }

  void _field(String label, String value) =>
      console.writeln('     ${label.padRight(12)} $value');

  String _heading(JsonMap record) =>
      '#${record['posterNumber'].toString().padLeft(2, '0')}  ${record['name']}';

  String _coordinates(JsonMap record) =>
      formatCoordinates(latitudeOf(record)!, longitudeOf(record)!);

  String _flagSuffix(String originalStatus) =>
      flaggedStatuses.contains(originalStatus)
      ? ' · poster flag: ${statusLabel(originalStatus)}'
      : '';

  int _notFound(int number) {
    console.writeln(
      'No pandal has poster number $number. Run `list` to see them all.',
    );
    return exitError;
  }

  int _cancel() {
    console.writeln(_cancelled);
    return exitOk;
  }

  int _notVerified() {
    console.writeln('Not verified. $_cancelled');
    return exitOk;
  }
}
