import 'package:flutter/material.dart';

import '../models/visit.dart';
import '../theme/app_colors.dart';

/// Marigold stars for a visit's rating. Read-only unless [onChanged] is
/// given; then tapping a star sets the rating, and tapping the current one
/// again clears it.
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.rating,
    this.onChanged,
    this.size = 16,
  });

  final int? rating;
  final ValueChanged<int?>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final rating = this.rating ?? 0;
    final onChanged = this.onChanged;

    Icon star(int value) => Icon(
      value <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
      size: size,
      color: value <= rating ? AppColors.marigold : AppColors.outlineStrong,
    );

    if (onChanged == null) {
      return Semantics(
        label: rating == 0
            ? 'Not rated'
            : 'Rated $rating out of ${Visit.maxRating}',
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var value = 1; value <= Visit.maxRating; value++) star(value),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var value = 1; value <= Visit.maxRating; value++)
          IconButton(
            tooltip: value == rating
                ? 'Clear rating'
                : 'Rate $value out of ${Visit.maxRating}',
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(value == rating ? null : value),
            icon: star(value),
          ),
      ],
    );
  }
}
