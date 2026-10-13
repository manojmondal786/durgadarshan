import 'package:flutter/foundation.dart';

import 'coordinates.dart';
import 'visiting_hours.dart';

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

/// How closely a map pin matches the venue, when it came from an address
/// lookup rather than being entered by hand.
enum PinPrecision {
  venue('venue'),
  landmark('landmark'),
  street('street'),

  /// Only the neighbourhood or town centre, not the venue.
  area('area');

  const PinPrecision(this.jsonValue);

  final String jsonValue;

  static PinPrecision? fromJson(Object? value) {
    if (value == null) return null;
    for (final precision in values) {
      if (precision.jsonValue == value) return precision;
    }
    throw FormatException('Unknown coordinatesPrecision: $value');
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
    this.pinPrecision,
    this.listedVenues = const [],
    this.venueNeedsChecking = false,
    this.timings,
    this.schedule,
    this.planningCutoff,
    this.description,
    this.imageAsset,
    this.notes = const [],
    this.isFeatured = false,
  }) : assert(
         (latitude == null) == (longitude == null),
         'latitude and longitude must both be set or both be null',
       ),
       assert(
         schedule == null || planningCutoff == null,
         'a planning cutoff is only for pandals without a schedule',
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

    final rawSchedule = json['schedule'];
    final schedule = rawSchedule == null
        ? null
        : VisitingSchedule.fromJson(rawSchedule);

    final rawCutoff = json['planningCutoff'];
    ClockTime? planningCutoff;
    if (rawCutoff is Map<String, Object?> &&
        rawCutoff['status'] == 'tentative') {
      planningCutoff = ClockTime.parse(rawCutoff['time']);
    } else if (rawCutoff != null) {
      throw FormatException(
        'Pandal "planningCutoff" must be a tentative time or null',
        json,
      );
    }
    if (schedule != null && planningCutoff != null) {
      throw FormatException(
        'Pandal has a schedule, so it must not have a planning cutoff',
        json,
      );
    }

    final rawVerification = json['verification'];
    if (rawVerification != null && rawVerification is! Map<String, Object?>) {
      throw FormatException('Pandal "verification" must be an object', json);
    }
    final verification = rawVerification as Map<String, Object?>?;

    // The full poster address, kept when `address` holds only one venue.
    final posterAddress = optionalString('posterAddress');
    final listedVenues = [
      ...?posterAddress?.split(' / ').map(_trimEnd).where((v) => v.isNotEmpty),
    ];

    final rawCautions = json['posterCautions'];
    if (rawCautions != null && rawCautions is! List) {
      throw FormatException('Pandal "posterCautions" must be a list', json);
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
      pinPrecision: PinPrecision.fromJson(
        verification?['coordinatesPrecision'],
      ),
      listedVenues: listedVenues.length > 1
          ? List.unmodifiable(listedVenues)
          : const [],
      venueNeedsChecking: (rawCautions as List?)?.isNotEmpty ?? false,
      timings: optionalString('timings'),
      schedule: schedule,
      planningCutoff: planningCutoff,
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

  /// How closely the pin matches the venue; null when it was entered by
  /// hand or there is no pin.
  final PinPrecision? pinPrecision;

  /// Every venue the poster gives, when it gives more than one; otherwise
  /// empty. [address] holds the one the pin is placed at.
  final List<String> listedVenues;

  /// The poster itself doubts this entry's venue, e.g. "(Need to check)".
  /// Its wording stays in the data file; the app only asks visitors to
  /// check before they travel.
  final bool venueNeedsChecking;

  /// Darshan timings exactly as printed on the poster, null when it gives
  /// none. [schedule] holds the same hours in structured form.
  final String? timings;

  /// Actual visiting hours, from the poster or the organisers.
  final VisitingSchedule? schedule;

  /// A tentative time to plan a visit around, for pandals with no
  /// [schedule]. It is not a closing time: show it only with its
  /// disclaimer, and never use it for open/closed status or reminders.
  final ClockTime? planningCutoff;

  /// The About Pandal text. Its sources are kept in the data file.
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

  /// The pin marks only the neighbourhood, so the address, not the pin,
  /// leads to the venue.
  bool get pinShowsAreaOnly =>
      hasVerifiedLocation && pinPrecision == PinPrecision.area;

  static String _trimEnd(String text) =>
      text.trim().replaceFirst(RegExp(r'[\s.,]+$'), '');
}
