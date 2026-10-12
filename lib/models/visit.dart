import 'dart:convert';

import 'package:flutter/foundation.dart';

/// The user's own record of a darshan: when they visited a pandal, and
/// optionally their rating and a note. Kept on the device only.
@immutable
class Visit {
  const Visit({
    required this.pandalId,
    required this.visitedAt,
    this.rating,
    this.note,
  }) : assert(rating == null || (rating >= 1 && rating <= maxRating));

  static const maxRating = 5;
  static const maxNoteLength = 280;

  final String pandalId;

  /// Local date and time of the visit.
  final DateTime visitedAt;

  /// 1 to [maxRating] stars, or null when not rated.
  final int? rating;
  final String? note;

  Map<String, Object?> toJson() => {
    'pandalId': pandalId,
    'visitedAt': visitedAt.toIso8601String(),
    if (rating != null) 'rating': rating,
    if (note != null) 'note': note,
  };

  /// Throws a [FormatException] if [json] isn't a valid visit.
  factory Visit.fromJson(Map<String, Object?> json) {
    final pandalId = json['pandalId'];
    final visitedAt = json['visitedAt'];
    final rating = json['rating'];
    final note = json['note'];
    if (pandalId is! String || pandalId.isEmpty) {
      throw FormatException(
        'Visit "pandalId" must be a non-empty string',
        json,
      );
    }
    final time = visitedAt is String ? DateTime.tryParse(visitedAt) : null;
    if (time == null) {
      throw FormatException('Visit "visitedAt" must be a date and time', json);
    }
    if (rating != null &&
        (rating is! int || rating < 1 || rating > maxRating)) {
      throw FormatException('Visit "rating" must be 1 to $maxRating', json);
    }
    if (note != null && note is! String) {
      throw FormatException('Visit "note" must be a string', json);
    }
    return Visit(
      pandalId: pandalId,
      visitedAt: time,
      rating: rating as int?,
      note: note as String?,
    );
  }

  /// One stored record, as written by [encode]; null if it can't be read.
  static Visit? tryDecode(String record) {
    try {
      final json = jsonDecode(record);
      return json is Map<String, Object?> ? Visit.fromJson(json) : null;
    } on FormatException {
      return null;
    }
  }

  String encode() => jsonEncode(toJson());

  @override
  bool operator ==(Object other) =>
      other is Visit &&
      other.pandalId == pandalId &&
      other.visitedAt == visitedAt &&
      other.rating == rating &&
      other.note == note;

  @override
  int get hashCode => Object.hash(pandalId, visitedAt, rating, note);
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "Sat 17 Oct", with the year added when it isn't the current one.
String formatVisitDate(DateTime date, {DateTime? now}) {
  final year = date.year == (now ?? DateTime.now()).year ? '' : ' ${date.year}';
  return '${_weekdays[date.weekday - 1]} ${date.day} '
      '${_months[date.month - 1]}$year';
}

/// "7:05 pm".
String formatVisitTime(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${time.hour < 12 ? 'am' : 'pm'}';
}

/// "Sat 17 Oct, 7:05 pm".
String formatVisitDateTime(DateTime time, {DateTime? now}) =>
    '${formatVisitDate(time, now: now)}, ${formatVisitTime(time)}';
