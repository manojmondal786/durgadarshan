import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_images.dart';
import '../theme/app_typography.dart';
import 'faded_image.dart';
import 'motion/entrance.dart';
import 'responsive.dart';

/// Home banner from the redesign: marigolds and a lit pandal framing the
/// "Shubho Sharodiya" greeting, then search and area shortcuts.
class FestiveHero extends StatelessWidget {
  const FestiveHero({
    super.key,
    required this.searchField,
    required this.shortcuts,
    required this.onFavourites,
    this.reveal = true,
  });

  /// Animates the banner in, e.g. on the screen's first frame.
  final bool reveal;
  final Widget searchField;
  final Widget shortcuts;
  final VoidCallback onFavourites;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final artWidth = (width * 0.29).clamp(92.0, 150.0);
    final bandHeight = width < 360 ? 136.0 : 152.0;

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Column(
        children: [
          SizedBox(height: MediaQuery.paddingOf(context).top),
          SizedBox(
            height: bandHeight,
            child: Stack(
              children: [
                // Warm glow behind the pandal, as in the redesign.
                Positioned(
                  right: -artWidth * 0.4,
                  bottom: -artWidth * 0.5,
                  width: artWidth * 2.2,
                  height: artWidth * 2.2,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [Color(0x99C6231E), Color(0x00C6231E)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  bottom: 0,
                  width: artWidth,
                  height: artWidth * 340 / 348,
                  child: Entrance(
                    enabled: reveal,
                    delay: const Duration(milliseconds: 150),
                    duration: const Duration(milliseconds: 750),
                    offset: const Offset(-32, 8),
                    child: const FadedImage(
                      asset: AppImages.headerMarigolds,
                      fadeRight: 0.4,
                      fadeTop: 0.35,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  width: artWidth,
                  height: artWidth * 320 / 344,
                  child: Entrance(
                    enabled: reveal,
                    delay: const Duration(milliseconds: 150),
                    duration: const Duration(milliseconds: 750),
                    offset: const Offset(32, 8),
                    child: const FadedImage(
                      asset: AppImages.headerTemple,
                      fadeLeft: 0.3,
                      fadeTop: 0.25,
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 10,
                  child: IconButton.filled(
                    tooltip: 'Your favourites',
                    onPressed: onFavourites,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.maroonInk.withValues(
                        alpha: 0.45,
                      ),
                      foregroundColor: AppColors.goldBright,
                    ),
                    icon: const Icon(Icons.favorite_rounded),
                  ),
                ),
                Positioned(
                  left: 56,
                  right: 56,
                  top: 30,
                  child: Entrance(
                    enabled: reveal,
                    delay: const Duration(milliseconds: 250),
                    offset: const Offset(0, 10),
                    child: const _Greeting(),
                  ),
                ),
              ],
            ),
          ),
          ContentWidth(
            maxWidth: 640,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Entrance(
                enabled: reveal,
                delay: const Duration(milliseconds: 350),
                offset: const Offset(0, 12),
                child: searchField,
              ),
            ),
          ),
          const SizedBox(height: 14),
          ContentWidth(child: shortcuts),
          const SizedBox(height: 10),
          // Top of the ivory content sheet, rounded over the maroon.
          const DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.ivory,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: SizedBox(height: 22, width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final small = MediaQuery.sizeOf(context).width < 360;
    return Column(
      children: [
        Text(
          'শুভ শারদীয়া',
          semanticsLabel: 'Shubho Sharodiya',
          textAlign: TextAlign.center,
          style: AppTypography.bengali(
            fontSize: small ? 26 : 30,
            color: AppColors.goldLight,
            height: 1.25,
          ),
        ),
        ExcludeSemantics(
          child: Text(
            'Shubho Sharodiya',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.goldLight,
              fontWeight: FontWeight.w500,
              fontSize: small ? 17 : 19,
            ),
          ),
        ),
      ],
    );
  }
}
