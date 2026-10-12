import 'dart:convert';
import 'dart:io';

import 'package:durga_darshan/data/pandal_repository.dart';

/// The bundled pandal data as it currently stands.
PandalRepository loadBundledPandals() => PandalRepository.fromJsonString(
  File(PandalRepository.assetPath).readAsStringSync(),
);

/// The bundled JSON as transcribed from the poster, before any location
/// work: no coordinates, no verification details, and each pandal back on
/// its poster status. Tests use this so they don't depend on which locations
/// have been verified so far.
Map<String, Object?> posterDocument() {
  final document = jsonDecode(
    File(PandalRepository.assetPath).readAsStringSync(),
  ) as Map<String, Object?>;
  final records = (document['pandals'] as List).cast<Map<String, Object?>>();
  return {
    ...document,
    'pandals': [
      for (final raw in records)
        {
          for (final entry in raw.entries)
            if (entry.key != 'verification') entry.key: entry.value,
          'latitude': null,
          'longitude': null,
          'verificationStatus': _posterStatus(raw),
        },
    ],
  };
}

/// [posterDocument] as the app sees it.
PandalRepository posterSnapshot() =>
    PandalRepository.fromJsonString(jsonEncode(posterDocument()));

Object? _posterStatus(Map<String, Object?> record) {
  final status = record['verificationStatus'];
  if (status != 'verified') return status;
  final verification = record['verification'] as Map<String, Object?>?;
  return verification?['statusBeforeVerification'] ?? 'unverified';
}
