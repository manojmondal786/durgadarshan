import 'package:latlong2/latlong.dart';

import 'pandal.dart';

/// Alerts fire for pandals within this distance.
const nearbyRadiusMeters = 3000.0;

class NearbyPandal {
  const NearbyPandal(this.pandal, this.meters);

  final Pandal pandal;
  final double meters;
}

/// Pandals with a verified location within [radiusMeters] of [position],
/// nearest first.
List<NearbyPandal> pandalsWithin(
  LatLng position,
  Iterable<Pandal> pandals, {
  double radiusMeters = nearbyRadiusMeters,
}) {
  const distance = Distance();
  return [
      for (final pandal in pandals)
        if (pandal.hasVerifiedLocation)
          NearbyPandal(
            pandal,
            distance.as(
              LengthUnit.Meter,
              position,
              LatLng(pandal.latitude!, pandal.longitude!),
            ),
          ),
    ].where((nearby) => nearby.meters <= radiusMeters).toList()
    ..sort((a, b) => a.meters.compareTo(b.meters));
}

/// "850 m" below a kilometre, otherwise "1.2 km".
String formatDistance(double meters) {
  final rounded = (meters / 50).round() * 50;
  return rounded < 1000
      ? '$rounded m'
      : '${(meters / 1000).toStringAsFixed(1)} km';
}
