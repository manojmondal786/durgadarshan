import 'package:flutter/foundation.dart';

/// A time of day as stored in the data, "HH:mm" on a 24-hour clock.
@immutable
class ClockTime {
  const ClockTime(this.hour, this.minute)
    : assert(hour >= 0 && hour < 24),
      assert(minute >= 0 && minute < 60);

  /// Parses "HH:mm", e.g. "09:00" or "20:30". Throws a [FormatException]
  /// for anything else.
  factory ClockTime.parse(Object? value) {
    final match = value is String ? _pattern.firstMatch(value) : null;
    if (match == null) {
      throw FormatException('Expected a time as "HH:mm"', value);
    }
    return ClockTime(int.parse(match[1]!), int.parse(match[2]!));
  }

  static final _pattern = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');

  final int hour;
  final int minute;

  bool get isMidnight => hour == 0 && minute == 0;

  /// "9:00 AM", "12:30 PM", "12:00 AM".
  String format() {
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final period = hour < 12 ? 'AM' : 'PM';
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  bool operator ==(Object other) =>
      other is ClockTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => format();
}

/// Where a pandal's visiting hours come from.
enum ScheduleSource {
  /// Printed on the community poster; not confirmed with the organisers.
  poster('poster'),

  /// Confirmed by the organisers.
  organisers('organisers');

  const ScheduleSource(this.jsonValue);

  final String jsonValue;

  static ScheduleSource fromJson(Object? value) {
    for (final source in values) {
      if (source.jsonValue == value) return source;
    }
    throw FormatException('Unknown schedule source: $value');
  }
}

/// A window when visitors are welcome, e.g. morning darshan.
@immutable
class VisitingSession {
  const VisitingSession({
    required this.label,
    required this.start,
    required this.end,
  });

  final String label;
  final ClockTime start;
  final ClockTime end;
}

/// A ritual at a fixed time within the day, e.g. evening aarti.
@immutable
class ScheduledEvent {
  const ScheduledEvent({required this.label, required this.time});

  final String label;
  final ClockTime time;
}

/// Actual visiting hours from a named source. Pandals without any have no
/// schedule; they may carry a tentative planning cutoff instead, which is
/// kept apart so it can never pass for real hours.
@immutable
class VisitingSchedule {
  const VisitingSchedule({
    required this.source,
    this.sessions = const [],
    this.events = const [],
  });

  /// Parses a pandal's "schedule" object. Throws a [FormatException] for
  /// unknown sources, missing labels, bad times or an empty schedule.
  factory VisitingSchedule.fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw FormatException('"schedule" must be an object or null', json);
    }

    String label(Map<String, Object?> item) {
      final value = item['label'];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      throw FormatException('Schedule entries need a label', item);
    }

    List<T> list<T>(String key, T Function(Map<String, Object?>) parse) {
      final value = json[key] ?? const <Object?>[];
      if (value is! List) {
        throw FormatException('Schedule "$key" must be a list', json);
      }
      return List.unmodifiable([
        for (final item in value)
          if (item is Map<String, Object?>)
            parse(item)
          else
            throw FormatException('Schedule "$key" must hold objects', json),
      ]);
    }

    final schedule = VisitingSchedule(
      source: ScheduleSource.fromJson(json['source']),
      sessions: list(
        'sessions',
        (item) => VisitingSession(
          label: label(item),
          start: ClockTime.parse(item['start']),
          end: ClockTime.parse(item['end']),
        ),
      ),
      events: list(
        'events',
        (item) => ScheduledEvent(
          label: label(item),
          time: ClockTime.parse(item['time']),
        ),
      ),
    );
    if (schedule.sessions.isEmpty && schedule.events.isEmpty) {
      throw FormatException('"schedule" lists no sessions or events', json);
    }
    return schedule;
  }

  final ScheduleSource source;
  final List<VisitingSession> sessions;
  final List<ScheduledEvent> events;
}
