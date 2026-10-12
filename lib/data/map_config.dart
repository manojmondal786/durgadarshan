import 'package:latlong2/latlong.dart';

/// Map defaults and the OpenStreetMap tile source.
///
/// The public OSM tile servers are a donated, shared resource with a usage
/// policy (https://operations.osmfoundation.org/policies/tiles/): identify
/// the app, show attribution, respect caching, and never bulk-download.
abstract final class MapConfig {
  /// Centre of Ahmedabad for the initial city-wide view. This is the city's
  /// centre, not the location of any pandal.
  static const ahmedabadCenter = LatLng(23.0225, 72.5714);
  static const initialZoom = 11.0;
  static const minZoom = 5.0;

  /// Highest zoom the OSM standard tile layer serves.
  static const maxZoom = 19.0;

  static const osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const osmCopyrightUrl = 'https://www.openstreetmap.org/copyright';

  /// Sent in the tile requests' User-Agent so the tile server can identify
  /// the app. Keep in sync with the Android applicationId / iOS bundle id.
  static const userAgentPackageName = 'com.durgadarshan.ahmedabad';

  /// Upper bound for the on-device tile cache (not used on the web, where
  /// the browser cache applies). Freshness follows the servers' HTTP headers.
  static const maxTileCacheBytes = 100 * 1024 * 1024;
}
