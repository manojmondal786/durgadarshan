import 'package:durga_darshan/data/map_config.dart';
import 'package:durga_darshan/models/coordinates.dart';
import 'package:latlong2/latlong.dart';

typedef JsonMap = Map<String, Object?>;

const statusVerified = 'verified';
const statusUnverified = 'unverified';
const statusNeedsCheck = 'needs_check';
const statusConflicting = 'conflicting';
const validStatuses = {
  statusVerified,
  statusUnverified,
  statusNeedsCheck,
  statusConflicting,
};

/// Statuses that carry a warning from the source poster.
const flaggedStatuses = {statusNeedsCheck, statusConflicting};

/// Where a pandal's location stands in the verification workflow.
enum LocationState {
  /// Explicitly confirmed; shown on the app's map.
  verified,

  /// Coordinates recorded but not yet confirmed; hidden from the app.
  candidate,

  /// No coordinates yet.
  unresolved,
}

/// Input the user should correct and enter again.
class InputException implements Exception {
  const InputException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// How closely a pin matches the venue, when it came from an address lookup
/// rather than being entered by hand.
String precisionLabel(Object? precision) => switch (precision) {
  'venue' => 'venue',
  'landmark' => 'nearby landmark',
  'street' => 'street-level',
  'area' => 'area-level',
  _ => '$precision',
};

String statusLabel(Object? status) => switch (status) {
  statusVerified => 'verified',
  statusUnverified => 'unverified',
  statusNeedsCheck => 'needs check',
  statusConflicting => 'unclear location',
  _ => '$status',
};

// ---------------------------------------------------------------------------
// Coordinate input

/// Decimal degrees: optional sign, up to three integer digits, optional
/// fraction. No exponents, degree signs, hemisphere letters or commas.
final _decimalDegrees = RegExp(r'^[+-]?\d{1,3}(?:\.(\d*))?$');

/// About 11 m at the equator; anything coarser can't pin a venue.
const minDecimalPlaces = 4;

/// Coordinates further than this from Ahmedabad trigger a warning. The
/// furthest listed towns (Bavla, Sanand, Gandhinagar) are well within it.
const nearbyRadiusKm = 60.0;

double parseLatitude(String input) => _parseDegrees(
  input,
  label: 'Latitude',
  range: '-90 and 90',
  isValid: Coordinates.isValidLatitude,
);

double parseLongitude(String input) => _parseDegrees(
  input,
  label: 'Longitude',
  range: '-180 and 180',
  isValid: Coordinates.isValidLongitude,
);

/// Parses "latitude, longitude", as copied from most map apps.
({double latitude, double longitude}) parseCoordinatePair(String input) {
  final parts = input.split(',');
  if (parts.length != 2) {
    throw const InputException(
      'Enter latitude and longitude separated by one comma, '
      'e.g. 23.022500, 72.571400.',
    );
  }
  return (
    latitude: parseLatitude(parts[0]),
    longitude: parseLongitude(parts[1]),
  );
}

double _parseDegrees(
  String input, {
  required String label,
  required String range,
  required bool Function(double) isValid,
}) {
  final text = input.trim();
  if (text.isEmpty) throw InputException('$label is required.');
  final match = _decimalDegrees.firstMatch(text);
  if (match == null) {
    throw InputException(
      '$label must be in decimal degrees, e.g. 23.022500 '
      '(use a minus sign for south/west; no °, N/E/S/W or commas).',
    );
  }
  if ((match.group(1) ?? '').length < minDecimalPlaces) {
    throw InputException(
      '$label needs at least $minDecimalPlaces decimal places '
      '(about 10 m precision).',
    );
  }
  final value = double.parse(text);
  if (!isValid(value)) throw InputException('$label must be between $range.');
  return double.parse(value.toStringAsFixed(6));
}

double distanceFromAhmedabadKm(double latitude, double longitude) =>
    const Distance().as(
      LengthUnit.Kilometer,
      MapConfig.ahmedabadCenter,
      LatLng(latitude, longitude),
    );

/// Plausibility warnings for coordinates far from Ahmedabad, including a hint
/// when latitude and longitude look swapped.
List<String> locationWarnings(double latitude, double longitude) {
  final km = distanceFromAhmedabadKm(latitude, longitude);
  if (km <= nearbyRadiusKm) return const [];
  return [
    'These coordinates are ${km.round()} km from Ahmedabad.',
    if (Coordinates.isValidPair(longitude, latitude) &&
        distanceFromAhmedabadKm(longitude, latitude) <= nearbyRadiusKm)
      'Swapped, they would be in the Ahmedabad area. Did you enter '
          'longitude first?',
  ];
}

String formatCoordinates(double latitude, double longitude) =>
    '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

/// openstreetmap.org link for checking coordinates by eye. Printed only;
/// the tool never fetches anything.
String openStreetMapLink(double latitude, double longitude) {
  final lat = latitude.toStringAsFixed(6);
  final lng = longitude.toStringAsFixed(6);
  return 'https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=18/$lat/$lng';
}

String isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

// ---------------------------------------------------------------------------
// Reading records

List<JsonMap> pandalsOf(JsonMap document) =>
    (document['pandals'] as List).cast<JsonMap>();

int? indexOfPosterNumber(JsonMap document, int posterNumber) {
  final pandals = pandalsOf(document);
  for (var i = 0; i < pandals.length; i++) {
    if (pandals[i]['posterNumber'] == posterNumber) return i;
  }
  return null;
}

double? _asDouble(Object? value) => value is num ? value.toDouble() : null;

double? latitudeOf(JsonMap record) => _asDouble(record['latitude']);

double? longitudeOf(JsonMap record) => _asDouble(record['longitude']);

bool hasCoordinates(JsonMap record) =>
    Coordinates.isValidPair(latitudeOf(record), longitudeOf(record));

JsonMap verificationOf(JsonMap record) =>
    record['verification'] as JsonMap? ?? const {};

LocationState locationStateOf(JsonMap record) {
  if (!hasCoordinates(record)) return LocationState.unresolved;
  return record['verificationStatus'] == statusVerified
      ? LocationState.verified
      : LocationState.candidate;
}

/// The poster's status for a record, even after it has been verified.
String originalStatusOf(JsonMap record) {
  final status = record['verificationStatus'] as String;
  if (status != statusVerified) return status;
  return verificationOf(record)['statusBeforeVerification'] as String? ??
      statusUnverified;
}

// ---------------------------------------------------------------------------
// Validation

/// Everything wrong with [document], or an empty list if it is safe to use.
///
/// Mirrors the app's parsing rules and adds workflow rules: a verified
/// pandal needs valid coordinates, and coordinates need a recorded source.
List<String> validateDocument(Object? document) {
  if (document is! Map<String, Object?>) {
    return ['The file must contain a JSON object.'];
  }
  final pandals = document['pandals'];
  if (pandals is! List) return ['The file must contain a "pandals" list.'];

  final problems = <String>[];
  final ids = <String>{};
  final posterNumbers = <int>{};

  for (var i = 0; i < pandals.length; i++) {
    final record = pandals[i];
    if (record is! Map<String, Object?>) {
      problems.add('Entry ${i + 1} is not a JSON object.');
      continue;
    }
    final number = record['posterNumber'];
    final label = number is int ? '#$number' : 'Entry ${i + 1}';
    void problem(String message) => problems.add('$label: $message');

    if (number is! int) {
      problem('"posterNumber" must be a whole number.');
    } else if (!posterNumbers.add(number)) {
      problem('poster number is used more than once.');
    }

    for (final key in const ['id', 'name', 'area', 'city']) {
      final value = record[key];
      if (value is! String || value.trim().isEmpty) {
        problem('"$key" must be a non-empty string.');
      }
    }
    final id = record['id'];
    if (id is String && !ids.add(id)) {
      problem('id "$id" is used more than once.');
    }

    for (final key in const [
      'address',
      'posterAddress',
      'timings',
      'description',
      'image',
    ]) {
      final value = record[key];
      if (value != null && value is! String) {
        problem('"$key" must be a string or null.');
      }
    }

    final lat = record['latitude'];
    final lng = record['longitude'];
    if ((lat == null) != (lng == null)) {
      problem('latitude and longitude must both be set or both be null.');
    } else if (lat != null) {
      if (lat is! num || !Coordinates.isValidLatitude(lat.toDouble())) {
        problem('latitude must be a number between -90 and 90.');
      }
      if (lng is! num || !Coordinates.isValidLongitude(lng.toDouble())) {
        problem('longitude must be a number between -180 and 180.');
      }
    }

    final status = record['verificationStatus'];
    if (!validStatuses.contains(status)) {
      problem('unknown verificationStatus "$status".');
    } else if (status == statusVerified && !hasCoordinates(record)) {
      problem('is marked verified but has no valid coordinates.');
    }

    for (final key in const ['notes', 'posterCautions']) {
      final list = record[key];
      if (list != null &&
          (list is! List ||
              list.any((n) => n is! String || n.trim().isEmpty))) {
        problem('"$key" must be null or a list of non-empty strings.');
      }
    }

    final verification = record['verification'];
    if (verification != null) {
      if (verification is! Map<String, Object?> ||
          verification.values.any((v) => v != null && v is! String)) {
        problem('"verification" must be an object of strings or nulls.');
      } else {
        final before = verification['statusBeforeVerification'];
        if (before != null &&
            (before == statusVerified || !validStatuses.contains(before))) {
          problem('unknown statusBeforeVerification "$before".');
        }
      }
    }
    if (hasCoordinates(record)) {
      final source = verification is Map<String, Object?>
          ? verification['coordinatesSource']
          : null;
      if (source is! String || source.trim().isEmpty) {
        problem(
          'has coordinates but no recorded source. Record them with the '
          '`set` command.',
        );
      }
    }
  }
  return problems;
}

// ---------------------------------------------------------------------------
// Updating records. Each returns a new record; inputs are never modified.

const _verificationKeys = [
  'coordinatesSource',
  'coordinatesRecordedOn',
  'coordinatesPrecision',
  'verifiedOn',
  'verificationNote',
  'statusBeforeVerification',
];

/// Records candidate coordinates. Never marks the record verified: a
/// previously verified record returns to its status from before
/// verification. Notes and all other fields are kept as they are.
JsonMap withCandidate(
  JsonMap record, {
  required double latitude,
  required double longitude,
  required String source,
  required String recordedOn,
}) {
  return _merge(record, {
    'latitude': latitude,
    'longitude': longitude,
    'verificationStatus': originalStatusOf(record),
    'verification': _verification(record, {
      'coordinatesSource': source,
      'coordinatesRecordedOn': recordedOn,
      // Hand-entered coordinates replace any looked-up approximation.
      'coordinatesPrecision': null,
      'verifiedOn': null,
      'verificationNote': null,
      'statusBeforeVerification': null,
    }),
  });
}

/// Marks a candidate verified, remembering its previous status so poster
/// flags such as "needs check" are not lost.
JsonMap withVerified(
  JsonMap record, {
  required String note,
  required String verifiedOn,
}) {
  if (locationStateOf(record) != LocationState.candidate) {
    throw StateError('Only candidates can be verified.');
  }
  return _merge(record, {
    'verificationStatus': statusVerified,
    'verification': _verification(record, {
      'verifiedOn': verifiedOn,
      'verificationNote': note,
      'statusBeforeVerification': record['verificationStatus'],
    }),
  });
}

/// Removes coordinates and any verification, restoring the poster status.
JsonMap withoutLocation(JsonMap record) => _merge(record, {
  'latitude': null,
  'longitude': null,
  'verificationStatus': originalStatusOf(record),
  'verification': null,
});

JsonMap replaceRecord(JsonMap document, int index, JsonMap record) {
  final pandals = [...pandalsOf(document)];
  pandals[index] = record;
  return {...document, 'pandals': pandals};
}

JsonMap _verification(JsonMap record, JsonMap changes) {
  final current = verificationOf(record);
  return {
    for (final key in _verificationKeys)
      key: changes.containsKey(key) ? changes[key] : current[key],
    for (final entry in current.entries)
      if (!_verificationKeys.contains(entry.key)) entry.key: entry.value,
  };
}

/// Applies [changes] keeping the record's key order; a new "verification"
/// key goes straight after "verificationStatus".
JsonMap _merge(JsonMap record, JsonMap changes) {
  final result = <String, Object?>{};
  for (final key in record.keys) {
    result[key] = changes.containsKey(key) ? changes[key] : record[key];
    if (key == 'verificationStatus' &&
        !record.containsKey('verification') &&
        changes.containsKey('verification')) {
      result['verification'] = changes['verification'];
    }
  }
  for (final entry in changes.entries) {
    result.putIfAbsent(entry.key, () => entry.value);
  }
  return result;
}
