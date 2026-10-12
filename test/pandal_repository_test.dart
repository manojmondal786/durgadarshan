import 'dart:io';

import 'package:durga_darshan/data/pandal_repository.dart';
import 'package:durga_darshan/models/pandal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PandalRepository repository;

  setUpAll(() {
    repository = PandalRepository.fromJsonString(
      File(PandalRepository.assetPath).readAsStringSync(),
    );
  });

  List<int?> numbers(List<Pandal> pandals) =>
      pandals.map((p) => p.posterNumber).toList();

  group('fromJsonString', () {
    const minimal = '"name": "N", "area": "A", "city": "C"';

    test('rejects duplicate ids', () {
      expect(
        () => PandalRepository.fromJsonString(
          '{"pandals": [{"id": "x", $minimal}, {"id": "x", $minimal}]}',
        ),
        throwsFormatException,
      );
    });

    test('rejects documents without a pandals list', () {
      expect(
        () => PandalRepository.fromJsonString('[]'),
        throwsFormatException,
      );
      expect(
        () => PandalRepository.fromJsonString('{"pandals": {}}'),
        throwsFormatException,
      );
      expect(
        () => PandalRepository.fromJsonString('{"pandals": ["x"]}'),
        throwsFormatException,
      );
    });
  });

  group('search', () {
    test('matches names, areas and addresses case-insensitively', () {
      expect(numbers(repository.search(query: 'KALIBARI')), [2, 18]);
      expect(numbers(repository.search(query: 'maninagar')), [3, 5]);
      expect(numbers(repository.search(query: 'bengal')), [8, 13]);
      expect(numbers(repository.search(query: '382415')), [9, 10]);
      expect(numbers(repository.search(query: 'Gandhinagar')), [21]);
    });

    test('requires every word to match', () {
      expect(numbers(repository.search(query: 'adinath jadeshwar')), [10]);
      expect(numbers(repository.search(query: '  sector   28 ')), [21]);
      expect(repository.search(query: 'kalibari sanand'), isEmpty);
    });

    test('returns everything for a blank query and nothing for no match', () {
      expect(repository.search(), hasLength(25));
      expect(repository.search(query: '   '), hasLength(25));
      expect(repository.search(query: 'no such pandal'), isEmpty);
    });
  });

  group('filters', () {
    test('narrow by area', () {
      expect(numbers(repository.search(area: 'Ghodasar')), [4, 22]);
      expect(numbers(repository.search(area: 'Odhav')), [9, 10]);
      expect(numbers(repository.search(area: 'Odhav', query: 'indrapark')), [
        9,
      ]);
      expect(repository.search(area: 'Nowhere'), isEmpty);
    });

    test('narrow to favourite ids', () {
      const favourites = {'sanand-durga-puja', 'vaibhav-hall'};
      expect(numbers(repository.search(onlyIds: favourites)), [4, 25]);
      expect(
        repository.search(onlyIds: favourites, area: 'Ghodasar').single.id,
        'vaibhav-hall',
      );
      expect(repository.search(onlyIds: const {}), isEmpty);
    });

    test('areas are distinct and sorted', () {
      final areas = repository.areas;
      expect(areas, hasLength(22));
      expect(areas.toSet(), hasLength(areas.length));
      expect(areas, [...areas]..sort());
    });

    test('areas by pandal count put the busiest areas first', () {
      final areas = repository.areasByPandalCount;
      expect(areas.take(4), ['Ghodasar', 'Maninagar', 'Odhav', 'Airport Road']);
      expect(areas.toSet(), repository.areas.toSet());
    });
  });

  group('featured', () {
    test('falls back to the first entries in list order', () {
      expect(numbers(repository.featured), [1, 2, 3, 4, 5, 6, 7, 8]);
    });

    test('uses pandals marked as featured when there are any', () {
      final custom = PandalRepository(const [
        Pandal(id: 'a', name: 'A', area: 'X', city: 'C'),
        Pandal(id: 'b', name: 'B', area: 'X', city: 'C', isFeatured: true),
      ]);
      expect(custom.featured.single.id, 'b');
    });
  });

  test('byId finds pandals and returns null for unknown ids', () {
    expect(repository.byId('sola')!.posterNumber, 16);
    expect(repository.byId('missing'), isNull);
  });
}
