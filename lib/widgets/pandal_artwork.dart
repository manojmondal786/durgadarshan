import 'package:flutter/material.dart';

import '../models/pandal.dart';
import '../theme/app_colors.dart';
import '../theme/app_images.dart';

/// A pandal's bundled photo, or a representative image from the redesign
/// when it has none.
class PandalArtwork extends StatelessWidget {
  const PandalArtwork({
    super.key,
    required this.pandal,
    this.representativeAsset,
    this.borderRadius = BorderRadius.zero,
  });

  final Pandal pandal;

  /// Image to use instead of the pandal's usual representative image, e.g.
  /// the larger details header.
  final String? representativeAsset;
  final BorderRadius borderRadius;

  /// True when no photo of this pandal is bundled.
  static bool isRepresentative(Pandal pandal) => pandal.imageAsset == null;

  @override
  Widget build(BuildContext context) {
    final photo = pandal.imageAsset;
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.asset(
        photo ?? representativeAsset ?? AppImages.representativeFor(pandal),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => const DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.maroonGradient),
        ),
      ),
    );
  }
}

/// Marks an image as illustrative rather than a photo of the pandal.
class RepresentativeImageTag extends StatelessWidget {
  const RepresentativeImageTag({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.photo_outlined,
            size: 13,
            color: AppColors.goldLight,
          ),
          const SizedBox(width: 5),
          Text(
            'Representative image',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.onMaroon,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
