import 'package:flutter/foundation.dart';

/// Search and filter state for the pandal list, shared so the Home screen can
/// open the list with a query or area already applied.
class BrowseController extends ChangeNotifier {
  String _query = '';
  String? _area;
  bool _favouritesOnly = false;

  String get query => _query;

  /// Selected area, or null for all areas.
  String? get area => _area;
  bool get favouritesOnly => _favouritesOnly;

  bool get hasFilters => _query.isNotEmpty || _area != null || _favouritesOnly;

  set query(String value) {
    if (value == _query) return;
    _query = value;
    notifyListeners();
  }

  set area(String? value) {
    if (value == _area) return;
    _area = value;
    notifyListeners();
  }

  set favouritesOnly(bool value) {
    if (value == _favouritesOnly) return;
    _favouritesOnly = value;
    notifyListeners();
  }

  void clear() {
    _query = '';
    _area = null;
    _favouritesOnly = false;
    notifyListeners();
  }
}
