import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Floating title over the map: "Pandal Map" and how many pandals it shows.
class MapTitlePill extends StatelessWidget {
  const MapTitlePill({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 9),
      decoration: ShapeDecoration(
        gradient: AppColors.headerGradient,
        shape: StadiumBorder(
          side: BorderSide(color: AppColors.goldBright.withValues(alpha: 0.6)),
        ),
        shadows: AppColors.raisedShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: AppTypography.heading(
                fontSize: 17,
                color: AppColors.onMaroon,
              ),
            ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: AppColors.goldLight),
          ),
        ],
      ),
    );
  }
}

/// Reset-view and zoom buttons: white controls as in the redesign.
class MapControls extends StatelessWidget {
  const MapControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
    this.onShowParking,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  /// Centres the map on the parked vehicle; the button shows only when set.
  final VoidCallback? onShowParking;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ControlSurface(
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: 'Reset map view',
            onPressed: onReset,
            icon: const Icon(Icons.filter_center_focus_rounded),
          ),
        ),
        if (onShowParking case final onShowParking?) ...[
          const SizedBox(height: 12),
          _ControlSurface(
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: 'Show my parked vehicle',
              onPressed: onShowParking,
              icon: const Icon(Icons.directions_car_rounded),
            ),
          ),
        ],
        const SizedBox(height: 12),
        _ControlSurface(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Zoom in',
                onPressed: onZoomIn,
                icon: const Icon(Icons.add_rounded),
              ),
              const SizedBox(
                width: 26,
                child: Divider(height: 1, color: AppColors.outlineStrong),
              ),
              IconButton(
                tooltip: 'Zoom out',
                onPressed: onZoomOut,
                icon: const Icon(Icons.remove_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ControlSurface extends StatelessWidget {
  const _ControlSurface({required this.shape, required this.child});

  final ShapeBorder shape;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: shape,
      elevation: 3,
      shadowColor: AppColors.maroonInk.withValues(alpha: 0.35),
      clipBehavior: Clip.antiAlias,
      child: IconTheme.merge(
        data: const IconThemeData(color: AppColors.ink),
        child: child,
      ),
    );
  }
}

/// Always-visible "© OpenStreetMap contributors" credit, linking to the
/// OSM copyright page as the tile usage policy requires.
class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Material(
          color: AppColors.card.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                '© OpenStreetMap contributors',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.maroon,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.maroon.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown when map tiles fail to load, e.g. when offline.
class MapTileErrorBanner extends StatelessWidget {
  const MapTileErrorBanner({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.maroonDeep.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(14),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
        child: Row(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.goldLight,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Map tiles couldn’t load. Check your connection.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.onMaroon),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: AppColors.goldLight),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Centres bottom overlays and keeps them readable on wide screens.
class MapOverlayWidth extends StatelessWidget {
  const MapOverlayWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: child,
      ),
    );
  }
}
