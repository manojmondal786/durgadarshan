import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What the app remembers between launches: favourites, the darshan log,
/// the saved parking spot, whether nearby alerts are on, and which pandals
/// have already alerted today. It stays on the device; nothing is sent anywhere.
abstract interface class AppStorage {
  /// The device's storage, or [MemoryStorage] (nothing kept between
  /// launches) if it can't be opened, so the app still works.
  static Future<AppStorage> open() async {
    try {
      return _DeviceStorage(
        await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(
            allowList: _DeviceStorage.keys,
          ),
        ),
      );
    } catch (error) {
      debugPrint(
        'Device storage unavailable, keeping settings in memory: '
        '$error',
      );
      return MemoryStorage();
    }
  }

  /// Ids of the pandals the user hearted, in the order they were added.
  List<String> get favouriteIds;
  Future<void> saveFavouriteIds(List<String> ids);

  /// The darshan log: one encoded `Visit` per visited pandal.
  List<String> get visitRecords;
  Future<void> saveVisitRecords(List<String> records);

  /// The saved parking spot, encoded, or null when none is saved.
  String? get parkingSpotRecord;
  Future<void> saveParkingSpotRecord(String? record);

  /// Whether the user closed the web version's install banner.
  bool get installHintDismissed;
  Future<void> saveInstallHintDismissed(bool dismissed);

  /// Whether the user left nearby alerts switched on.
  bool get nearbyAlertsOn;
  Future<void> saveNearbyAlertsOn(bool on);

  /// Pandals that have already alerted, as `<date>|<pandal id>`.
  List<String> get alertedPandals;
  Future<void> saveAlertedPandals(List<String> keys);
}

/// Keeps everything in memory, e.g. in tests or when the device storage
/// can't be opened.
class MemoryStorage implements AppStorage {
  MemoryStorage({
    List<String> favouriteIds = const [],
    List<String> visitRecords = const [],
    this.parkingSpotRecord,
    this.installHintDismissed = false,
    this.nearbyAlertsOn = false,
    List<String> alertedPandals = const [],
  }) : favouriteIds = List.unmodifiable(favouriteIds),
       visitRecords = List.unmodifiable(visitRecords),
       alertedPandals = List.unmodifiable(alertedPandals);

  @override
  List<String> favouriteIds;

  @override
  List<String> visitRecords;

  @override
  String? parkingSpotRecord;

  @override
  bool installHintDismissed;

  @override
  bool nearbyAlertsOn;

  @override
  List<String> alertedPandals;

  @override
  Future<void> saveFavouriteIds(List<String> ids) async =>
      favouriteIds = List.unmodifiable(ids);

  @override
  Future<void> saveVisitRecords(List<String> records) async =>
      visitRecords = List.unmodifiable(records);

  @override
  Future<void> saveParkingSpotRecord(String? record) async =>
      parkingSpotRecord = record;

  @override
  Future<void> saveInstallHintDismissed(bool dismissed) async =>
      installHintDismissed = dismissed;

  @override
  Future<void> saveNearbyAlertsOn(bool on) async => nearbyAlertsOn = on;

  @override
  Future<void> saveAlertedPandals(List<String> keys) async =>
      alertedPandals = List.unmodifiable(keys);
}

/// Shared preferences: SharedPreferences on Android, NSUserDefaults on iOS
/// and localStorage on the web.
class _DeviceStorage implements AppStorage {
  _DeviceStorage(this._preferences);

  final SharedPreferencesWithCache _preferences;

  static const _favourites = 'favouriteIds';
  static const _visits = 'visits';
  static const _parking = 'parkingSpot';
  static const _installHint = 'installHintDismissed';
  static const _alertsOn = 'nearbyAlertsOn';
  static const _alerted = 'alertedPandals';
  static const keys = {
    _favourites,
    _visits,
    _parking,
    _installHint,
    _alertsOn,
    _alerted,
  };

  @override
  List<String> get favouriteIds =>
      _preferences.getStringList(_favourites) ?? const [];

  @override
  List<String> get visitRecords =>
      _preferences.getStringList(_visits) ?? const [];

  @override
  String? get parkingSpotRecord => _preferences.getString(_parking);

  @override
  bool get installHintDismissed => _preferences.getBool(_installHint) ?? false;

  @override
  bool get nearbyAlertsOn => _preferences.getBool(_alertsOn) ?? false;

  @override
  List<String> get alertedPandals =>
      _preferences.getStringList(_alerted) ?? const [];

  @override
  Future<void> saveFavouriteIds(List<String> ids) =>
      _save(() => _preferences.setStringList(_favourites, ids));

  @override
  Future<void> saveVisitRecords(List<String> records) =>
      _save(() => _preferences.setStringList(_visits, records));

  @override
  Future<void> saveParkingSpotRecord(String? record) => _save(
    () => record == null
        ? _preferences.remove(_parking)
        : _preferences.setString(_parking, record),
  );

  @override
  Future<void> saveInstallHintDismissed(bool dismissed) =>
      _save(() => _preferences.setBool(_installHint, dismissed));

  @override
  Future<void> saveNearbyAlertsOn(bool on) =>
      _save(() => _preferences.setBool(_alertsOn, on));

  @override
  Future<void> saveAlertedPandals(List<String> keys) =>
      _save(() => _preferences.setStringList(_alerted, keys));

  /// A failed write only means the setting isn't kept for next time, so it
  /// is logged rather than surfaced.
  static Future<void> _save(Future<void> Function() write) async {
    try {
      await write();
    } catch (error) {
      debugPrint('Couldn’t save a setting: $error');
    }
  }
}
