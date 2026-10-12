import 'package:flutter/widgets.dart';

import '../data/pandal_repository.dart';
import 'browse_controller.dart';
import 'favourites_controller.dart';
import 'nearby_alerts_controller.dart';
import 'parking_controller.dart';
import 'visits_controller.dart';

/// Makes the repository and shared controllers available to every route.
/// Widgets rebuild on controller changes via [ListenableBuilder].
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.repository,
    required this.favourites,
    required this.visits,
    required this.parking,
    required this.browse,
    required this.nearbyAlerts,
    required super.child,
  });

  final PandalRepository repository;
  final FavouritesController favourites;
  final VisitsController visits;
  final ParkingController parking;
  final BrowseController browse;
  final NearbyAlertsController nearbyAlerts;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found in context');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      repository != oldWidget.repository ||
      favourites != oldWidget.favourites ||
      visits != oldWidget.visits ||
      parking != oldWidget.parking ||
      browse != oldWidget.browse ||
      nearbyAlerts != oldWidget.nearbyAlerts;
}
