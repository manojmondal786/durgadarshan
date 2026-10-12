import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'coordinates.dart';

/// Where the user parked: a GPS fix taken when they tapped Save My Parking,
/// and an optional note such as "Basement 2, pillar 14". Kept on the device
/// only.
@immutable
class ParkingSpot {
  const ParkingSpot({
    required this.latitude,
    required this.longitude,
    required this.savedAt,
    this.accuracyMeters,
    this.note,
  });

  static const maxNoteLength = 100;

  /// Above this, the card warns that the spot is approximate.
  static const roughAccuracyMeters = 50.0;

  final double latitude;
  final double longitude;

  /// Local time the spot was saved.
  final DateTime savedAt;

  /// The fix's horizontal accuracy, when the device reported one.
  final double? accuracyMeters;
  final String? note;

  LatLng get point => LatLng(latitude, longitude);

  bool get isRough => (accuracyMeters ?? 0) > roughAccuracyMeters;

  ParkingSpot withNote(String? note) => ParkingSpot(
    latitude: latitude,
    longitude: longitude,
    savedAt: savedAt,
    accuracyMeters: accuracyMeters,
    note: note,
  );

  Map<String, Object?> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'savedAt': savedAt.toIso8601String(),
    if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
    if (note != null) 'note': note,
  };

  /// Throws a [FormatException] if [json] isn't a valid parking spot.
  factory ParkingSpot.fromJson(Map<String, Object?> json) {
    final latitude = json['latitude'];
    final longitude = json['longitude'];
    final savedAt = json['savedAt'];
    final accuracy = json['accuracyMeters'];
    final note = json['note'];
    if (latitude is! num ||
        longitude is! num ||
        !Coordinates.isValidPair(latitude.toDouble(), longitude.toDouble())) {
      throw FormatException('Parking spot needs valid coordinates', json);
    }
    final time = savedAt is String ? DateTime.tryParse(savedAt) : null;
    if (time == null) {
      throw FormatException('Parking spot "savedAt" must be a time', json);
    }
    if (accuracy != null && accuracy is! num) {
      throw FormatException('Parking spot "accuracyMeters" must be a number');
    }
    if (note != null && note is! String) {
      throw FormatException('Parking spot "note" must be a string', json);
    }
    return ParkingSpot(
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      savedAt: time,
      accuracyMeters: (accuracy as num?)?.toDouble(),
      note: note as String?,
    );
  }

  /// The stored form, as written by [encode]; null if it can't be read.
  static ParkingSpot? tryDecode(String? record) {
    if (record == null) return null;
    try {
      final json = jsonDecode(record);
      return json is Map<String, Object?> ? ParkingSpot.fromJson(json) : null;
    } on FormatException {
      return null;
    }
  }

  String encode() => jsonEncode(toJson());

  @override
  bool operator ==(Object other) =>
      other is ParkingSpot &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.savedAt == savedAt &&
      other.accuracyMeters == accuracyMeters &&
      other.note == note;

  @override
  int get hashCode =>
      Object.hash(latitude, longitude, savedAt, accuracyMeters, note);
}
