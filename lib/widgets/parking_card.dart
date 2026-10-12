import 'package:flutter/material.dart';

import '../models/parking_spot.dart';
import '../models/proximity.dart';
import '../models/visit.dart';
import '../services/external_maps.dart';
import '../state/app_scope.dart';
import '../state/parking_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Home card for the parking spot saver: Save My Parking stores where the
/// user is now, and Navigate to my vehicle hands walking directions back to
/// it to their maps app.
class ParkingCard extends StatelessWidget {
  const ParkingCard({super.key, required this.onShowOnMap});

  /// Opens the Map tab on the saved spot.
  final VoidCallback onShowOnMap;

  static const vehicleLabel = 'My parked vehicle';

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final parking = scope.parking;
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: parking,
      builder: (context, _) {
        final spot = parking.spot;
        final (
          String? problem,
          bool canOpenSettings,
        ) = switch (parking.status) {
          ParkingStatus.idle || ParkingStatus.locating => (null, false),
          ParkingStatus.locationDenied => (
            'Location access was declined. Tap Save My Parking to ask again.',
            false,
          ),
          ParkingStatus.locationDeniedForever => (
            'Location access is blocked. Allow it in Settings to save your '
                'parking.',
            true,
          ),
          ParkingStatus.locationServiceOff => (
            'Location is turned off on this device. Turn it on to save your '
                'parking.',
            true,
          ),
          ParkingStatus.noFix => (
            'Couldn’t get your location. Try again in the open, away from '
                'tall buildings.',
            false,
          ),
        };

        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppColors.cardShadow,
          ),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.headerGradient,
                        ),
                        child: const Icon(
                          Icons.directions_car_rounded,
                          color: AppColors.goldBright,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'My Parking',
                          style: AppTypography.heading(fontSize: 17),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (spot == null)
                    Text(
                      'Parked near a pandal? Save the spot, then find your '
                      'way back to your vehicle later.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    )
                  else
                    _SpotDetails(spot: spot),
                  if (parking.isLocating) ...[
                    const SizedBox(height: 10),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        'Finding your location…',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.maroon,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const LinearProgressIndicator(
                      color: AppColors.maroon,
                      backgroundColor: AppColors.outline,
                    ),
                  ],
                  if (problem != null) ...[
                    const SizedBox(height: 10),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        problem,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.vermilion,
                        ),
                      ),
                    ),
                    if (canOpenSettings)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: parking.openSettings,
                          icon: const Icon(Icons.settings_outlined, size: 18),
                          label: const Text('Open settings'),
                        ),
                      ),
                  ],
                  const SizedBox(height: 12),
                  if (spot == null)
                    FilledButton.icon(
                      onPressed: parking.isLocating
                          ? null
                          : () => _save(context, parking),
                      icon: const Icon(Icons.local_parking_rounded),
                      label: const Text('Save My Parking'),
                    )
                  else ...[
                    FilledButton.icon(
                      onPressed: () => _navigate(context, spot),
                      icon: const Icon(Icons.directions_walk_rounded),
                      label: const Text('Navigate to my vehicle'),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: onShowOnMap,
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: const Text('Show on map'),
                        ),
                        TextButton.icon(
                          onPressed: () => _editNote(context, parking, spot),
                          icon: const Icon(Icons.edit_note_rounded, size: 18),
                          label: Text(
                            spot.note == null ? 'Add note' : 'Edit note',
                          ),
                        ),
                        TextButton.icon(
                          onPressed: parking.isLocating
                              ? null
                              : () => _save(context, parking),
                          icon: const Icon(Icons.my_location_rounded, size: 18),
                          label: const Text('Update spot'),
                        ),
                        TextButton.icon(
                          onPressed: () => _clear(context, parking, spot),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                          ),
                          label: const Text('Clear'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Saves where the user is now, first confirming before replacing a
  /// saved spot, so a stray tap can't lose the way back to the vehicle.
  static Future<void> _save(
    BuildContext context,
    ParkingController parking,
  ) async {
    final current = parking.spot;
    if (current != null) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Replace your parking spot?'),
          content: Text(
            'The spot saved at ${formatVisitTime(current.savedAt)} will be '
            'replaced by where you are now.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Replace'),
            ),
          ],
        ),
      );
      if (replace != true) return;
    }
    await parking.saveHere();
  }

  static Future<void> _navigate(BuildContext context, ParkingSpot spot) async {
    final opened = await ExternalMaps.open(
      ExternalMaps.directionsTo(spot.point, label: vehicleLabel),
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Couldn’t open a maps app.')),
        );
    }
  }

  static Future<void> _editNote(
    BuildContext context,
    ParkingController parking,
    ParkingSpot spot,
  ) async {
    final note = await showDialog<String>(
      context: context,
      builder: (_) => _NoteDialog(initial: spot.note),
    );
    if (note != null) parking.setNote(note);
  }

  static void _clear(
    BuildContext context,
    ParkingController parking,
    ParkingSpot spot,
  ) {
    parking.clear();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Parking spot cleared.'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => parking.restore(spot),
          ),
        ),
      );
  }
}

/// When the spot was saved, the nearest pandal, and the user's note.
class _SpotDetails extends StatelessWidget {
  const _SpotDetails({required this.spot});

  final ParkingSpot spot;

  /// Pandals further than this aren't named as a landmark.
  static const _landmarkRadiusMeters = 1000.0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted);
    final nearest = pandalsWithin(
      spot.point,
      AppScope.of(context).repository.mappable,
      radiusMeters: _landmarkRadiusMeters,
    ).firstOrNull;
    final note = spot.note;
    final accuracy = spot.accuracyMeters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Saved ${formatVisitDateTime(spot.savedAt)}', style: muted),
        if (nearest != null) ...[
          const SizedBox(height: 2),
          Text(
            'Near ${nearest.pandal.name} · '
            '${formatDistance(nearest.meters)}',
            style: muted,
          ),
        ],
        if (spot.isRough && accuracy != null) ...[
          const SizedBox(height: 4),
          Text(
            'Approximate spot (within about ${accuracy.round()} m): the GPS '
            'signal was weak. Update it in the open if you can.',
            style: textTheme.bodySmall?.copyWith(color: AppColors.terracotta),
          ),
        ],
        if (note != null) ...[
          const SizedBox(height: 6),
          Text(
            note,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.ink,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

/// Edits the parking note, e.g. "Basement 2, pillar 14". Pops the new note,
/// or null when cancelled.
class _NoteDialog extends StatefulWidget {
  const _NoteDialog({required this.initial});

  final String? initial;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late final _note = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Parking note'),
      content: TextField(
        controller: _note,
        autofocus: true,
        maxLength: ParkingSpot.maxNoteLength,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'e.g. Basement 2, near pillar 14',
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_note.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
