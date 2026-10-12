import 'dart:convert';
import 'dart:io';

import 'records.dart';

/// A problem with the data file that stops the tool.
class DataFileException implements Exception {
  const DataFileException(this.message, [this.problems = const []]);

  final String message;
  final List<String> problems;

  @override
  String toString() => [message, ...problems.map((p) => '  - $p')].join('\n');
}

/// The file's contents as read, kept to detect changes before saving.
class LoadedPandals {
  const LoadedPandals(this.raw, this.document);

  final String raw;
  final JsonMap document;
}

String encodeDocument(JsonMap document) =>
    '${const JsonEncoder.withIndent('  ').convert(document)}\n';

/// Reads and safely rewrites the pandal JSON file.
///
/// Every save backs up the current file to `backups/` beside it, writes the
/// new content to a temporary file in the same folder, checks it, and then
/// renames it over the original so the file is never left half-written.
class PandalDataFile {
  PandalDataFile(this.path, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final String path;
  final DateTime Function() _now;

  File get _file => File(path);

  Directory get backupDirectory =>
      Directory('${_file.parent.path}${Platform.pathSeparator}backups');

  LoadedPandals load() {
    if (!_file.existsSync()) {
      throw DataFileException('Data file not found: $path');
    }
    final raw = _file.readAsStringSync();
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error) {
      throw DataFileException('$path is not valid JSON: ${error.message}');
    }
    final problems = validateDocument(decoded);
    if (problems.isNotEmpty) {
      throw DataFileException(
        '$path has problems. Fix them (or restore a backup) first:',
        problems,
      );
    }
    return LoadedPandals(raw, decoded as JsonMap);
  }

  /// Saves [document] in place of the file read as [loaded] and returns the
  /// backup's path. Nothing is written if [document] is invalid or the file
  /// has changed since it was loaded.
  String save(LoadedPandals loaded, JsonMap document) {
    final problems = validateDocument(document);
    if (problems.isNotEmpty) {
      throw DataFileException('Refusing to save invalid data:', problems);
    }
    final current = _file.readAsStringSync();
    if (current != loaded.raw) {
      throw DataFileException(
        '$path changed since it was read. Nothing was saved; run the command '
        'again.',
      );
    }

    final backup = _writeBackup(current);
    final temp = File(
      '${_file.parent.path}${Platform.pathSeparator}'
      '.${_file.uri.pathSegments.last}.$pid.'
      '${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    try {
      temp.writeAsStringSync(encodeDocument(document), flush: true);
      final written = validateDocument(jsonDecode(temp.readAsStringSync()));
      if (written.isNotEmpty) {
        throw DataFileException('The written file failed its check:', written);
      }
      temp.renameSync(path);
    } catch (_) {
      if (temp.existsSync()) temp.deleteSync();
      rethrow;
    }
    return backup.path;
  }

  File _writeBackup(String contents) {
    backupDirectory.createSync(recursive: true);
    final t = _now();
    String two(int n) => n.toString().padLeft(2, '0');
    final stamp =
        '${t.year}${two(t.month)}${two(t.day)}-'
        '${two(t.hour)}${two(t.minute)}${two(t.second)}';
    final base = _file.uri.pathSegments.last.replaceFirst(
      RegExp(r'\.json$'),
      '',
    );
    var backup = _backupFile('$base-$stamp.json');
    for (var n = 2; backup.existsSync(); n++) {
      backup = _backupFile('$base-$stamp-$n.json');
    }
    backup.writeAsStringSync(contents, flush: true);
    return backup;
  }

  File _backupFile(String name) =>
      File('${backupDirectory.path}${Platform.pathSeparator}$name');
}
