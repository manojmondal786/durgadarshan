import 'package:flutter/material.dart';

import '../models/pandal.dart';
import '../state/app_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_images.dart';
import '../theme/app_typography.dart';
import 'favourite_button.dart';
import 'motion/press_scale.dart';
import 'pandal_artwork.dart';

/// Card for the Home screen's "Explore Pandals" carousel.
class FeaturedPandalCard extends StatelessWidget {
  const FeaturedPandalCard({
    super.key,
    required this.pandal,
    required this.onTap,
    this.width = 208,
  });

  final Pandal pandal;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final number = pandal.posterNumber;
    return PressScale(
      child: SizedBox(
        width: width,
        child: _Lifted(
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        PandalArtwork(
                          pandal: pandal,
                          representativeAsset: AppImages.coverFor(pandal),
                        ),
                        if (number != null)
                          Positioned(
                            left: 8,
                            bottom: 8,
                            child: PosterNumberBadge(
                              number: number,
                              onImage: true,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 4, 4),
                    child: Text(
                      pandal.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.heading(fontSize: 15),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 0, 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: PandalMetaRow(
                            icon: Icons.location_on_outlined,
                            text: pandal.area,
                          ),
                        ),
                        FavouriteButton(pandal: pandal, compact: true),
                      ],
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

/// Row card for the pandal list and favourites.
class PandalListCard extends StatelessWidget {
  const PandalListCard({super.key, required this.pandal, required this.onTap});

  final Pandal pandal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final number = pandal.posterNumber;
    final timings = pandal.timings;
    final compact = MediaQuery.sizeOf(context).width < 360;
    final imageSize = compact ? 72.0 : 84.0;

    return PressScale(
      scale: 0.98,
      child: _Lifted(
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 2, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: imageSize,
                    height: imageSize + 4,
                    child: PandalArtwork(
                      pandal: pandal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
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
                                  style: AppTypography.heading(
                                    fontSize: 15.5,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          PandalMetaRow(
                            icon: Icons.location_on_outlined,
                            text: pandal.area,
                          ),
                          // Only printed timings; most pandals have none yet.
                          if (timings != null) ...[
                            const SizedBox(height: 4),
                            PandalMetaRow(
                              icon: Icons.schedule_rounded,
                              text: timings,
                            ),
                          ],
                          _VisitedMark(pandalId: pandal.id),
                        ],
                      ),
                    ),
                  ),
                  FavouriteButton(pandal: pandal),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Visited" under a pandal the user has marked as visited.
class _VisitedMark extends StatelessWidget {
  const _VisitedMark({required this.pandalId});

  final String pandalId;

  @override
  Widget build(BuildContext context) {
    final visits = AppScope.of(context).visits;
    return ListenableBuilder(
      listenable: visits,
      builder: (context, _) {
        if (!visits.isVisited(pandalId)) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: AppColors.maroon,
              ),
              const SizedBox(width: 5),
              Text(
                'Visited',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.maroon,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The pandal's number on the source poster, e.g. "#3".
class PosterNumberBadge extends StatelessWidget {
  const PosterNumberBadge({
    super.key,
    required this.number,
    this.onImage = false,
  });

  final int number;

  /// Light gold pill for use over artwork; otherwise a terracotta tag that
  /// sits before a pandal's name.
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w800,
      height: 1.1,
      color: onImage ? AppColors.maroonDeep : AppColors.onMaroon,
    );
    return Semantics(
      label: 'Poster number $number',
      excludeSemantics: true,
      child: Container(
        padding: onImage
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 5)
            : const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: onImage ? const Color(0xFFF8EBC4) : AppColors.terracotta,
          borderRadius: BorderRadius.circular(onImage ? 10 : 5),
        ),
        child: Text('#$number', style: style),
      ),
    );
  }
}

class PandalMetaRow extends StatelessWidget {
  const PandalMetaRow({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.terracotta),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.inkMuted),
          ),
        ),
      ],
    );
  }
}

/// Adds the warm card shadow behind a [Card].
class _Lifted extends StatelessWidget {
  const _Lifted({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.cardShadow,
      ),
      child: child,
    );
  }
}
