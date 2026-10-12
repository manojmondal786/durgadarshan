import 'package:flutter/foundation.dart';

import 'coordinates.dart';

/// How far a pandal's location can be trusted.
enum VerificationStatus {
  /// Confirmed in person or by the organisers; safe for maps and directions.
  verified('verified'),

  /// Taken from the source list but not yet confirmed.
  unverified('unverified'),

  /// The source list itself says the location needs checking.
  needsCheck('needs_check'),

  /// The source list gives more than one, or contradictory, locations.
  conflicting('conflicting');

  const VerificationStatus(this.jsonValue);

  final String jsonValue;

  static VerificationStatus fromJson(Object? value) {
    for (final status in values) {
      if (status.jsonValue == value) return status;
    }
    throw FormatException('Unknown verificationStatus: $value');
  }
}

/// A Durga Puja pandal listed in the app.
///
/// Unknown details are null rather than guessed. Coordinates are only used
/// once [verificationStatus] is [VerificationStatus.verified].
@immutable
class Pandal {
  const Pandal({
    required this.id,
    required this.name,
    required this.area,
    required this.city,
    this.posterNumber,
    this.address,
    this.latitude,
    this.longitude,
    this.verificationStatus = VerificationStatus.unverified,
    this.timings,
    this.description,
    this.imageAsset,
    this.notes = const [],
    this.isFeatured = false,
  }) : assert(
         (latitude == null) == (longitude == null),
         'latitude and longitude must both be set or both be null',
       );

  /// Parses one record of `assets/data/pandals.json`.
  ///
  /// Throws a [FormatException] for missing required fields, wrong types,
  /// out-of-range or half-specified coordinates, and unknown statuses.
  factory Pandal.fromJson(Map<String, Object?> json) {
    String requiredString(String key) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      throw FormatException('Pandal "$key" must be a non-empty string', json);
    }

    String? optionalString(String key) {
      final value = json[key];
      if (value == null) return null;
      if (value is String) {
        final trimmed = value.trim();
        return trimmed.isEmpty ? null : trimmed;
      }
      throw FormatException('Pandal "$key" must be a string or null', json);
    }

    double? coordinate(String key, bool Function(double) isValid) {
      final value = json[key];
      if (value == null) return null;
      if (value is num && isValid(value.toDouble())) return value.toDouble();
      throw FormatException('Pandal "$key" is not a valid coordinate', json);
    }

    final latitude = coordinate('latitude', Coordinates.isValidLatitude);
    final longitude = coordinate('longitude', Coordinates.isValidLongitude);
    if ((latitude == null) != (longitude == null)) {
      throw FormatException(
        'Pandal latitude and longitude must both be set or both be null',
        json,
      );
    }

    final posterNumber = json['posterNumber'];
    if (posterNumber != null && posterNumber is! int) {
      throw FormatException('Pandal "posterNumber" must be an integer', json);
    }

    final featured = json['featured'] ?? false;
    if (featured is! bool) {
      throw FormatException('Pandal "featured" must be a boolean', json);
    }

    final rawNotes = json['notes'];
    final notes = <String>[];
    if (rawNotes is List) {
      for (final note in rawNotes) {
        if (note is! String || note.trim().isEmpty) {
          throw FormatException('Pandal "notes" must be strings', json);
        }
        notes.add(note.trim());
      }
    } else if (rawNotes != null) {
      throw FormatException('Pandal "notes" must be a list or null', json);
    }

    return Pandal(
      id: requiredString('id'),
      posterNumber: posterNumber as int?,
      name: requiredString('name'),
      area: requiredString('area'),
      city: requiredString('city'),
      address: optionalString('address'),
      latitude: latitude,
      longitude: longitude,
      verificationStatus: VerificationStatus.fromJson(
        json['verificationStatus'] ?? VerificationStatus.unverified.jsonValue,
      ),
      timings: optionalString('timings'),
      description: optionalString('description'),
      imageAsset: optionalString('image'),
      notes: List.unmodifiable(notes),
      isFeatured: featured,
    );
  }

  final String id;

  /// Position on the source poster, kept for traceability.
  final int? posterNumber;
  final String name;

  /// Locality used for filtering, e.g. a neighbourhood or nearby town.
  final String area;
  final String city;
  final String? address;
  final double? latitude;
  final double? longitude;
  final VerificationStatus verificationStatus;

  /// Human-readable darshan timings, null when not announced.
  final String? timings;
  final String? description;

  /// Bundled photo, e.g. `assets/images/pandals/<id>.jpg`. Null shows the
  /// illustrated placeholder instead.
  final String? imageAsset;

  /// Caveats from the source, such as conflicting addresses.
  final List<String> notes;
  final bool isFeatured;

  /// Both coordinates are present and within range. Says nothing about
  /// whether they are correct; see [hasVerifiedLocation].
  bool get hasCoordinates => Coordinates.isValidPair(latitude, longitude);

  bool get isLocationVerified =>
      verificationStatus == VerificationStatus.verified;

  /// True only when the location may be pinned on the map or opened in a
  /// maps app: explicitly verified, with valid coordinates.
  bool get hasVerifiedLocation => isLocationVerified && hasCoordinates;
}
