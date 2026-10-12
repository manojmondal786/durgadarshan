import 'package:flutter/foundation.dart';

/// The pandals the user hearted. The app restores them from, and saves
/// them to, the device's storage, so they survive restarts.
class FavouritesController extends ChangeNotifier {
  FavouritesController({Iterable<String> initial = const []})
    : _ids = {...initial};

  final Set<String> _ids;

  /// In the order they were added.
  Set<String> get ids => Set.unmodifiable(_ids);

  bool isFavourite(String pandalId) => _ids.contains(pandalId);

  void toggle(String pandalId) {
    if (!_ids.remove(pandalId)) _ids.add(pandalId);
    notifyListeners();
  }
}
