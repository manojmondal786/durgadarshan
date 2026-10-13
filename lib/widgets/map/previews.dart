import 'package:flutter/material.dart';

import '../../models/pandal.dart';
import '../../models/parking_spot.dart';
import '../../models/visit.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../pandal_artwork.dart';
import '../pandal_cards.dart';

/// Bottom card for a tapped pin.
class PandalMapPreview extends StatelessWidget {
  const PandalMapPreview({
    super.key,
    required this.pandal,
    required this.onViewDetails,
    required this.onOpenInMaps,
    required this.onClose,
  });

  final Pandal pandal;
  final VoidCallback onViewDetails;
  final VoidCallback onOpenInMaps;
  final VoidCallback onClose;

  static const _buttonPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 12,
  );

  @override
  Widget build(BuildContext context) {
    final number = pandal.posterNumber;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.raisedShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 64,
                height: 66,
                child: PandalArtwork(
                  pandal: pandal,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (number != null) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: PosterNumberBadge(number: number),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            pandal.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.heading(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    PandalMetaRow(
                      icon: Icons.location_on_outlined,
                      text: pandal.area,
                    ),
                    if (pandal.pinShowsAreaOnly)
                      Padding(
                        // Lines up with the area name, past its icon.
                        padding: const EdgeInsets.only(left: 21, top: 2),
                        child: Text(
                          'Pin shows the area, not the exact venue',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.inkMuted),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Close preview',
                visualDensity: VisualDensity.compact,
                onPressed: onClose,
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(padding: _buttonPadding),
                    onPressed: onOpenInMaps,
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text(
                      'Open in Maps',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(padding: _buttonPadding),
                    onPressed: onViewDetails,
                    child: const Text(
                      'View details',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom card for the parked vehicle's marker.
class ParkingMapPreview extends StatelessWidget {
  const ParkingMapPreview({
    super.key,
    required this.spot,
    required this.onNavigate,
    required this.onClose,
  });

  final ParkingSpot spot;
  final VoidCallback onNavigate;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final note = spot.note;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.raisedShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car_rounded, color: AppColors.maroon),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your parked vehicle',
                  style: AppTypography.heading(fontSize: 17),
                ),
              ),
              IconButton(
                tooltip: 'Close preview',
                onPressed: onClose,
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
          Text(
            'Saved ${formatVisitDateTime(spot.savedAt)}',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
          ),
          if (note != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 12),
              child: Text(
                note,
                style: textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onNavigate,
                icon: const Icon(Icons.directions_walk_rounded),
                label: const Text('Navigate to my vehicle'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Preview for a pin shared by several pandals at the same spot.
class PandalGroupPreview extends StatelessWidget {
  const PandalGroupPreview({
    super.key,
    required this.pandals,
    required this.onViewDetails,
    required this.onOpenInMaps,
    required this.onClose,
  });

  final List<Pandal> pandals;
  final ValueChanged<Pandal> onViewDetails;
  final VoidCallback onOpenInMaps;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.raisedShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${pandals.length} pandals here',
                  style: AppTypography.heading(fontSize: 17),
                ),
              ),
              IconButton(
                tooltip: 'Close preview',
                onPressed: onClose,
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
          for (final pandal in pandals)
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onViewDetails(pandal),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: 46,
                      child: PandalArtwork(
                        pandal: pandal,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pandal.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleSmall,
                          ),
                          Text(
                            pandal.area,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.maroon,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenInMaps,
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Open in Maps'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
