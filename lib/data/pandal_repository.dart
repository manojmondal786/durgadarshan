import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/pandal.dart';

/// Read-only access to the pandal list bundled in [assetPath].
class PandalRepository {
  PandalRepository(List<Pandal> pandals) : pandals = List.unmodifiable(pandals);

  /// Parses the bundled JSON document; see [assetPath] for the format.
  ///
  /// Throws a [FormatException] if the document or any record is malformed,
  /// or if two records share an id.
  factory PandalRepository.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    final records = decoded is Map<String, Object?> ? decoded['pandals'] : null;
    if (records is! List) {
      throw const FormatException('Expected an object with a "pandals" list');
    }

    final pandals = <Pandal>[];
    final ids = <String>{};
    for (final record in records) {
      if (record is! Map<String, Object?>) {
        throw FormatException('Each pandal must be an object', record);
      }
      final pandal = Pandal.fromJson(record);
      if (!ids.add(pandal.id)) {
        throw FormatException('Duplicate pandal id: ${pandal.id}');
      }
      pandals.add(pandal);
    }
    return PandalRepository(pandals);
  }

  static const assetPath = 'assets/data/pandals.json';

  /// How many pandals Home shows when none are marked as featured.
  static const _highlightCount = 8;

  static Future<PandalRepository> loadFromAssets([AssetBundle? bundle]) async {
    final source = await (bundle ?? rootBundle).loadString(assetPath);
    return PandalRepository.fromJsonString(source);
  }

  // The list never changes, so the views below are worked out once, on
  // first use, rather than on every rebuild.
  final List<Pandal> pandals;

  /// Pandals eligible for a map pin: verified, with valid coordinates.
  /// Coordinates alone are never enough.
  late final List<Pandal> mappable = List.unmodifiable(
    pandals.where((pandal) => pandal.hasVerifiedLocation),
  );

  /// Pandals marked as featured, or the first few in list order when none
  /// are, so Home never implies a ranking the data doesn't make.
  late final List<Pandal> featured = () {
    final marked = pandals.where((pandal) => pandal.isFeatured).toList();
    return List<Pandal>.unmodifiable(
      marked.isNotEmpty ? marked : pandals.take(_highlightCount),
    );
  }();

  /// Distinct areas in alphabetical order.
  late final List<String> areas = List.unmodifiable(
    pandals.map((pandal) => pandal.area).toSet().toList()..sort(),
  );

  /// Distinct areas with the most pandals first, ties alphabetical.
  late final List<String> areasByPandalCount = () {
    final counts = <String, int>{};
    for (final pandal in pandals) {
      counts.update(pandal.area, (count) => count + 1, ifAbsent: () => 1);
    }
    return List<String>.unmodifiable(
      counts.keys.toList()..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        return byCount != 0 ? byCount : a.compareTo(b);
      }),
    );
  }();

  Pandal? byId(String id) {
    for (final pandal in pandals) {
      if (pandal.id == id) return pandal;
    }
    return null;
  }

  /// Every word of [query] must appear (case-insensitively) in the name,
  /// area, city or address. Results are then narrowed by [area] and, when
  /// given, to the ids in [onlyIds].
  List<Pandal> search({String query = '', String? area, Set<String>? onlyIds}) {
    final words = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    return pandals
        .where((pandal) {
          if (area != null && pandal.area != area) return false;
          if (onlyIds != null && !onlyIds.contains(pandal.id)) return false;
          if (words.isEmpty) return true;
          final haystack = [
            pandal.name,
            pandal.area,
            pandal.city,
            pandal.address ?? '',
          ].join(' ').toLowerCase();
          return words.every(haystack.contains);
        })
        .toList(growable: false);
  }
}
