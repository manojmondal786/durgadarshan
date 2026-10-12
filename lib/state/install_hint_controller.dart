import 'package:flutter/foundation.dart';

import '../services/app_storage.dart';
import '../services/install_target.dart';

/// The web version's banner inviting phone-browser users to install the
/// app. It stays closed once the user closes it.
class InstallHintController extends ChangeNotifier {
  InstallHintController({
    required InstallTarget? target,
    required this._storage,
  }) : _target = _storage.installHintDismissed ? null : target;

  final AppStorage _storage;
  InstallTarget? _target;

  /// What the banner suggests, or null when it isn't shown.
  InstallTarget? get target => _target;

  void dismiss() {
    if (_target == null) return;
    _target = null;
    _storage.saveInstallHintDismissed(true);
    notifyListeners();
  }
}
