import 'package:flutter/foundation.dart';

import '../models/visit.dart';

/// The user's darshan log: the pandals they have visited, when, and their
/// own rating and note for each. The app restores it from, and saves it to,
/// the device's storage.
class VisitsController extends ChangeNotifier {
  VisitsController({Iterable<Visit> initial = const []})
    : _visits = {for (final visit in initial) visit.pandalId: visit};

  final Map<String, Visit> _visits;

  int get count => _visits.length;

  bool isVisited(String pandalId) => _visits.containsKey(pandalId);

  Visit? visitOf(String pandalId) => _visits[pandalId];

  /// Most recent first.
  List<Visit> get visits =>
      _visits.values.toList()
        ..sort((a, b) => b.visitedAt.compareTo(a.visitedAt));

  /// Records a visit, replacing any earlier one for the same pandal.
  void save(Visit visit) {
    if (_visits[visit.pandalId] == visit) return;
    _visits[visit.pandalId] = visit;
    notifyListeners();
  }

  void remove(String pandalId) {
    if (_visits.remove(pandalId) != null) notifyListeners();
  }
}
