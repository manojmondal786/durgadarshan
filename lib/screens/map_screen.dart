import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/map_config.dart';
import '../models/pandal.dart';
import '../models/parking_spot.dart';
import '../services/external_maps.dart';
import '../state/app_scope.dart';
import '../state/parking_controller.dart';
import '../theme/app_images.dart';
import '../theme/app_motion.dart';
import '../widgets/faded_image.dart';
import '../widgets/parking_card.dart';
import '../widgets/map/overlays.dart';
import '../widgets/map/pins.dart';
import '../widgets/map/previews.dart';
import '../widgets/motion/entrance.dart';
import '../widgets/motion/first_reveal.dart';
import 'pandal_details_screen.dart';

/// Interactive OpenStreetMap view with a pin for every pandal that has a map
/// location, and the user's parked vehicle when they saved one.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.tileProvider});

  /// Tile source override, e.g. for tests. Defaults to OpenStreetMap over
  /// the network with an on-device cache that respects HTTP headers.
  final TileProvider? tileProvider;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

/// Pandals sharing one map position, shown as a single pin.
class _PinGroup {
  _PinGroup(this.key, this.point);

  final String key;
  final LatLng point;
  final pandals = <Pandal>[];
}

List<_PinGroup> _groupPins(List<Pandal> pins) {
  final groups = <String, _PinGroup>{};
  for (final pandal in pins) {
    final lat = pandal.latitude!;
    final lng = pandal.longitude!;
    final key = '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
    groups
        .putIfAbsent(key, () => _PinGroup(key, LatLng(lat, lng)))
        .pandals
        .add(pandal);
  }
  return groups.values.toList();
}

/// Frames every pin and the parked vehicle, leaving room for the controls
/// and bottom previews.
CameraFit? _fitPins(List<_PinGroup> groups, ParkingSpot? parking) {
  final points = [for (final group in groups) group.point, ?parking?.point];
  return points.isEmpty
      ? null
      : CameraFit.coordinates(
          coordinates: points,
          padding: const EdgeInsets.fromLTRB(40, 120, 72, 72),
          maxZoom: 15,
        );
}

/// [_MapScreenState._selectedKey] while the parked vehicle is selected.
const _parkingKey = 'parking';

/// How close the map comes when showing the parked vehicle.
const _parkingZoom = 17.0;

class _MapScreenState extends State<MapScreen> with FirstReveal {
  final _mapController = MapController();
  final _resetTiles = StreamController<void>.broadcast();

  // Disposed by the TileLayer that uses it.
  late final TileProvider _tileProvider =
      widget.tileProvider ??
      NetworkTileProvider(
        cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
          maxCacheSize: MapConfig.maxTileCacheBytes,
        ),
      );

  String? _selectedKey;
  bool _tilesFailing = false;
  bool _mapReady = false;
  ParkingController? _parking;

  /// Whether the map opens on the parked vehicle rather than all the pins,
  /// because Home's Show on map opened it.
  bool _startOnParking = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parking = AppScope.of(context).parking;
    if (parking != _parking) {
      final first = _parking == null;
      _parking?.removeListener(_onParking);
      _parking = parking..addListener(_onParking);
      if (first && parking.takeFocusRequest()) {
        _startOnParking = true;
        _selectedKey = _parkingKey;
      }
    }
  }

  @override
  void dispose() {
    _parking?.removeListener(_onParking);
    _mapController.dispose();
    _resetTiles.close();
    super.dispose();
  }

  void _onParking() {
    if (!mounted) return;
    setState(() {
      if (_parking?.spot == null && _selectedKey == _parkingKey) {
        _selectedKey = null;
      }
    });
    _showRequestedParking();
  }

  void _onMapReady() => _mapReady = true;

  /// Shows the parked vehicle if Home asked to, once the map can move.
  void _showRequestedParking() {
    if (_mapReady && (_parking?.takeFocusRequest() ?? false)) _showParking();
  }

  void _showParking() {
    final spot = _parking?.spot;
    if (spot == null) return;
    _mapController.move(spot.point, _parkingZoom);
    setState(() => _selectedKey = _parkingKey);
  }

  Future<void> _navigateToParking(ParkingSpot spot) async {
    final opened = await ExternalMaps.open(
      ExternalMaps.directionsTo(spot.point, label: ParkingCard.vehicleLabel),
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Couldn’t open a maps app.')),
        );
    }
  }

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    _mapController.move(
      camera.center,
      (camera.zoom + delta).clamp(MapConfig.minZoom, MapConfig.maxZoom),
    );
  }

  void _resetView(CameraFit? fit) {
    if (fit == null) {
      _mapController.move(MapConfig.ahmedabadCenter, MapConfig.initialZoom);
    } else {
      _mapController.fitCamera(fit);
    }
    setState(() => _selectedKey = null);
  }

  void _onTileError(TileImage tile, Object error, StackTrace? stackTrace) {
    if (!mounted || _tilesFailing) return;
    setState(() => _tilesFailing = true);
  }

  void _retryTiles() {
    setState(() => _tilesFailing = false);
    _resetTiles.add(null);
  }

  Future<void> _openInMaps(Pandal pandal) async {
    final opened = await ExternalMaps.open(ExternalMaps.linkFor(pandal));
    if (!opened && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Couldn’t open a maps app.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final pins = scope.repository.mappable;
    final groups = _groupPins(pins);
    final parkingSpot = scope.parking.spot;
    final fit = _fitPins(groups, parkingSpot);
    _PinGroup? selected;
    for (final group in groups) {
      if (group.key == _selectedKey) selected = group;
    }
    void close() => setState(() => _selectedKey = null);

    final Widget? bottomOverlay;
    if (_selectedKey == _parkingKey && parkingSpot != null) {
      bottomOverlay = ParkingMapPreview(
        key: const ValueKey(_parkingKey),
        spot: parkingSpot,
        onNavigate: () => _navigateToParking(parkingSpot),
        onClose: close,
      );
    } else if (selected != null && selected.pandals.length == 1) {
      final pandal = selected.pandals.single;
      bottomOverlay = PandalMapPreview(
        key: ValueKey(selected.key),
        pandal: pandal,
        onViewDetails: () => PandalDetailsScreen.open(context, pandal),
        onOpenInMaps: () => _openInMaps(pandal),
        onClose: close,
      );
    } else if (selected != null) {
      final group = selected;
      bottomOverlay = PandalGroupPreview(
        key: ValueKey(group.key),
        pandals: group.pandals,
        onViewDetails: (pandal) => PandalDetailsScreen.open(context, pandal),
        onOpenInMaps: () => _openInMaps(group.pandals.first),
        onClose: close,
      );
    } else {
      bottomOverlay = null;
    }

    final topInset = MediaQuery.paddingOf(context).top;
    final cornerWidth = (MediaQuery.sizeOf(context).width * 0.36).clamp(
      110.0,
      200.0,
    );

    return Scaffold(
      backgroundColor: _mapBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _startOnParking && parkingSpot != null
                    ? parkingSpot.point
                    : MapConfig.ahmedabadCenter,
                initialZoom: _startOnParking
                    ? _parkingZoom
                    : MapConfig.initialZoom,
                initialCameraFit: _startOnParking ? null : fit,
                minZoom: MapConfig.minZoom,
                maxZoom: MapConfig.maxZoom,
                backgroundColor: _mapBackground,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onTap: (_, _) => close(),
                onMapReady: _onMapReady,
              ),
              children: [
                TileLayer(
                  urlTemplate: MapConfig.osmTileUrl,
                  userAgentPackageName: MapConfig.userAgentPackageName,
                  tileProvider: _tileProvider,
                  maxNativeZoom: MapConfig.maxZoom.toInt(),
                  errorTileCallback: _onTileError,
                  evictErrorTileStrategy:
                      EvictErrorTileStrategy.notVisibleRespectMargin,
                  reset: _resetTiles.stream,
                ),
                MarkerLayer(
                  markers: [
                    for (final (index, group) in groups.indexed)
                      Marker(
                        point: group.point,
                        width: PandalPin.size.width,
                        height: PandalPin.size.height,
                        alignment: Alignment.topCenter,
                        // Pins drop in one after another when the map first
                        // opens; pins scrolled into view later just appear.
                        child: Entrance.staggered(
                          key: ValueKey(group.key),
                          index: index,
                          enabled: revealing,
                          start: const Duration(milliseconds: 300),
                          duration: const Duration(milliseconds: 520),
                          offset: const Offset(0, -26),
                          beginScale: 0.5,
                          curve: AppMotion.popCurve,
                          child: PandalPin(
                            label: group.pandals.length == 1
                                ? group.pandals.single.name
                                : '${group.pandals.length} pandals',
                            count: group.pandals.length,
                            selected: group.key == _selectedKey,
                            onTap: () =>
                                setState(() => _selectedKey = group.key),
                          ),
                        ),
                      ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    if (parkingSpot != null)
                      Marker(
                        point: parkingSpot.point,
                        width: ParkedVehicleMarker.size,
                        height: ParkedVehicleMarker.size,
                        child: ParkedVehicleMarker(
                          selected: _selectedKey == _parkingKey,
                          onTap: () =>
                              setState(() => _selectedKey = _parkingKey),
                        ),
                      ),
                  ],
                ),
                // Above the pins so it is never hidden.
                ListenableBuilder(
                  listenable: scope.nearbyAlerts,
                  builder: (context, _) {
                    final position = scope.nearbyAlerts.position;
                    return MarkerLayer(
                      markers: [
                        if (position != null)
                          Marker(
                            point: position,
                            width: UserLocationDot.size,
                            height: UserLocationDot.size,
                            child: const UserLocationDot(),
                          ),
                      ],
                    );
                  },
                ),
                MapAttribution(
                  onTap: () => ExternalMaps.openUrl(
                    Uri.parse(MapConfig.osmCopyrightUrl),
                  ),
                ),
              ],
            ),
          ),
          // Marigold corner from the redesign; purely decorative.
          Positioned(
            left: 0,
            top: 0,
            width: cornerWidth,
            height: cornerWidth * 268 / 432 + topInset * 0.5,
            child: const IgnorePointer(
              child: FadedImage(
                asset: AppImages.mapMarigolds,
                alignment: Alignment.bottomLeft,
                fadeRight: 0.45,
                fadeBottom: 0.45,
              ),
            ),
          ),
          Positioned(
            top: topInset + 10,
            left: 0,
            right: 0,
            child: Center(
              child: Entrance(
                delay: const Duration(milliseconds: 100),
                offset: const Offset(0, -16),
                child: MapTitlePill(
                  title: 'Pandal Map',
                  subtitle: switch (pins.length) {
                    0 => 'Ahmedabad and nearby areas',
                    1 => '1 pandal on the map',
                    final n => '$n pandals on the map',
                  },
                ),
              ),
            ),
          ),
          if (_tilesFailing)
            Positioned(
              top: topInset + 74,
              left: 12,
              right: 12,
              child: MapOverlayWidth(
                child: MapTileErrorBanner(onRetry: _retryTiles),
              ),
            ),
          Positioned(
            right: 12,
            top: topInset + (_tilesFailing ? 136 : 84),
            child: Entrance(
              delay: const Duration(milliseconds: 250),
              offset: const Offset(24, 0),
              child: MapControls(
                onZoomIn: () => _zoomBy(1),
                onZoomOut: () => _zoomBy(-1),
                onReset: () => _resetView(fit),
                onShowParking: parkingSpot == null ? null : _showParking,
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            // Leaves the attribution visible underneath.
            bottom: 34,
            child: MapOverlayWidth(
              child: AnimatedSwitcher(
                duration: AppMotion.duration(context, AppMotion.standard),
                switchInCurve: AppMotion.standardCurve,
                switchOutCurve: AppMotion.exitCurve,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: animation.drive(_overlayRise),
                    child: child,
                  ),
                ),
                child:
                    bottomOverlay ??
                    const SizedBox.shrink(key: ValueKey('none')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom cards rise into place from just below.
final _overlayRise = Tween(begin: const Offset(0, 0.25), end: Offset.zero);

/// Shown while tiles load or when they can't be fetched.
const _mapBackground = Color(0xFFF3E8D3);
