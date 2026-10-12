import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_images.dart';
import '../theme/app_typography.dart';
import 'faded_image.dart';

/// Home screen banner that opens the Map tab.
class ExploreMapCard extends StatelessWidget {
  const ExploreMapCard({
    super.key,
    required this.subtitle,
    required this.onExplore,
  });

  final String subtitle;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppColors.raisedShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: const BoxDecoration(gradient: AppColors.bannerGradient),
          child: InkWell(
            onTap: onExplore,
            child: SizedBox(
              height: 92,
              child: Row(
                children: [
                  const SizedBox(
                    width: 112,
                    child: FadedImage(
                      asset: AppImages.exploreMapDurga,
                      fadeRight: 0.35,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Explore on Map',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.heading(
                            fontSize: 20,
                            color: AppColors.onMaroon,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.goldLight),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.goldGradient,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.maroonDeep,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
