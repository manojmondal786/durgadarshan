import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'data/pandal_repository.dart';
import 'models/parking_spot.dart';
import 'models/visit.dart';
import 'screens/app_shell.dart';
import 'screens/pandal_details_screen.dart';
import 'screens/startup_screen.dart';
import 'services/alert_presenter.dart';
import 'services/app_storage.dart';
import 'services/location_source.dart';
import 'state/app_scope.dart';
import 'state/browse_controller.dart';
import 'state/favourites_controller.dart';
import 'state/nearby_alerts_controller.dart';
import 'state/parking_controller.dart';
import 'state/visits_controller.dart';
import 'theme/app_motion.dart';
import 'theme/app_theme.dart';

class DurgaDarshanApp extends StatefulWidget {
  const DurgaDarshanApp({
    super.key,
    this.repository,
    this.storage,
    this.mapTileProvider,
    this.locationSource,
    this.alertPresenter,
    this.splashDuration = AppMotion.splashMinimum,
  });

  /// Pandal data to show. When null, the bundled JSON is loaded at startup.
  final PandalRepository? repository;

  /// Where favourites, the darshan log, the parking spot and the alerts
  /// setting are kept.
  /// When null, the device's storage is opened at startup.
  final AppStorage? storage;

  /// Map tile source override, e.g. for tests. Defaults to OpenStreetMap.
  final TileProvider? mapTileProvider;

  /// Overrides for tests; default to the device's location and notifications.
  final LocationSource? locationSource;
  final AlertPresenter? alertPresenter;

  /// Least time the splash stays up while the bundled list loads. Not used
  /// when [repository] is given.
  final Duration splashDuration;

  @override
  State<DurgaDarshanApp> createState() => _DurgaDarshanAppState();
}

class _DurgaDarshanAppState extends State<DurgaDarshanApp> {
  final _browse = BrowseController();
  final _navigatorKey = GlobalKey<NavigatorState>();

  // Built once: a fresh ThemeData on every rebuild would compare unequal and
  // make MaterialApp animate a theme change each time the app state changes.
  final _theme = AppTheme.light();
  PandalRepository? _repository;
  AppStorage? _storage;

  /// Set up once the list and storage are loaded; see [_onLoaded].
  FavouritesController? _favourites;
  VisitsController? _visits;
  ParkingController? _parking;
  NearbyAlertsController? _nearbyAlerts;

  Object? _loadError;
  Timer? _splashTimer;
  bool _splashDone = false;

  /// A pandal to open once the app is showing, because its notification
  /// launched the app.
  String? _launchPandalId;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository;
    _storage = widget.storage;
    if (_repository == null) {
      _splashTimer = Timer(widget.splashDuration, () {
        if (!mounted) return;
        setState(() => _splashDone = true);
        _openLaunchPandal();
      });
    } else {
      _splashDone = true;
    }
    if (_repository != null && _storage != null) {
      _onLoaded();
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      _storage ??= await AppStorage.open();
      final repository = _repository ?? await PandalRepository.loadFromAssets();
      if (!mounted) return;
      setState(() => _repository = repository);
      _onLoaded();
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'durga_darshan',
          context: ErrorDescription('while loading the pandal list'),
        ),
      );
      if (mounted) setState(() => _loadError = error);
    }
  }

  void _retry() {
    setState(() => _loadError = null);
    _load();
  }

  /// Restores favourites, the darshan log, the parking spot and nearby
  /// alerts from storage, and notes a pandal whose notification launched the
  /// app.
  void _onLoaded() {
    final repository = _repository!;
    final storage = _storage!;
    final listed = {for (final pandal in repository.pandals) pandal.id};
    final favourites = FavouritesController(
      // Ids of pandals no longer listed are dropped.
      initial: storage.favouriteIds.where(listed.contains),
    );
    favourites.addListener(
      () => storage.saveFavouriteIds(favourites.ids.toList()),
    );
    final visits = VisitsController(
      initial: [
        for (final record in storage.visitRecords)
          if (Visit.tryDecode(record) case final visit?
              when listed.contains(visit.pandalId))
            visit,
      ],
    );
    visits.addListener(
      () => storage.saveVisitRecords([
        for (final visit in visits.visits) visit.encode(),
      ]),
    );
    final location = widget.locationSource ?? const DeviceLocationSource();
    final parking = ParkingController(
      location: location,
      initial: ParkingSpot.tryDecode(storage.parkingSpotRecord),
    );
    var savedSpot = parking.spot;
    parking.addListener(() {
      if (parking.spot == savedSpot) return;
      savedSpot = parking.spot;
      storage.saveParkingSpotRecord(savedSpot?.encode());
    });
    final presenter = widget.alertPresenter ?? LocalNotificationPresenter();
    _favourites = favourites;
    _visits = visits;
    _parking = parking;
    _nearbyAlerts = NearbyAlertsController(
      pandals: repository.mappable,
      location: location,
      presenter: presenter,
      storage: storage,
      onOpenPandal: _openPandal,
    )..restore();

    presenter.launchPandalId().then((id) {
      if (id == null || !mounted) return;
      _launchPandalId = id;
      _openLaunchPandal();
    });
  }

  /// Opens the pandal from the launching notification, once the splash has
  /// given way to the app.
  void _openLaunchPandal() {
    final id = _launchPandalId;
    if (id == null || !_splashDone) return;
    _launchPandalId = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openPandal(id);
    });
  }

  /// Opens a pandal's page from anywhere, e.g. a tapped notification.
  void _openPandal(String id) {
    final pandal = _repository?.byId(id);
    if (pandal == null) return;
    _navigatorKey.currentState?.push(PandalDetailsScreen.route(pandal));
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _favourites?.dispose();
    _visits?.dispose();
    _parking?.dispose();
    _browse.dispose();
    _nearbyAlerts?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = _repository;
    final favourites = _favourites;
    final visits = _visits;
    final parking = _parking;
    final nearbyAlerts = _nearbyAlerts;
    final loaded = repository != null && favourites != null;
    final Widget home;
    if (loaded && _splashDone) {
      home = AppShell(
        key: const ValueKey('app'),
        mapTileProvider: widget.mapTileProvider,
      );
    } else if (_loadError != null) {
      home = StartupScreen.error(key: const ValueKey('error'), onRetry: _retry);
    } else {
      home = const StartupScreen.loading(key: ValueKey('loading'));
    }

    return MaterialApp(
      title: 'Durga Darshan Ahmedabad',
      debugShowCheckedModeBanner: false,
      theme: _theme,
      navigatorKey: _navigatorKey,
      // Wraps the navigator so pushed routes can reach the shared state.
      builder: (context, child) {
        if (repository == null ||
            favourites == null ||
            visits == null ||
            parking == null ||
            nearbyAlerts == null) {
          return child!;
        }
        return AppScope(
          repository: repository,
          favourites: favourites,
          visits: visits,
          parking: parking,
          browse: _browse,
          nearbyAlerts: nearbyAlerts,
          child: child!,
        );
      },
      home: _FadeSwitcher(child: home),
    );
  }
}

/// Cross-fades from the splash to the app, which settles in from slightly
/// larger.
class _FadeSwitcher extends StatelessWidget {
  const _FadeSwitcher({required this.child});

  final Widget child;

  static final _settle = Tween(begin: 1.04, end: 1.0);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.duration(context, AppMotion.emphasized),
      switchInCurve: AppMotion.standardCurve,
      switchOutCurve: AppMotion.exitCurve,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: _settle.animate(animation), child: child),
      ),
      child: child,
    );
  }
}
