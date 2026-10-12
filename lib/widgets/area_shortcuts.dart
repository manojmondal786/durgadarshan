import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_images.dart';
import '../theme/app_motion.dart';
import 'motion/entrance.dart';
import 'motion/press_scale.dart';

/// Row of temple medallions on the Home banner: "All", then each area.
class AreaShortcutBar extends StatelessWidget {
  const AreaShortcutBar({
    super.key,
    required this.areas,
    required this.onAll,
    required this.onArea,
    this.reveal = true,
  });

  final List<String> areas;
  final VoidCallback onAll;
  final ValueChanged<String> onArea;

  /// Pops the medallions in one after another.
  final bool reveal;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: areas.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (context, index) {
          final area = index == 0 ? null : areas[index - 1];
          final medallion = area == null
              ? _Medallion(
                  image: AppImages.medallionAll,
                  label: 'All',
                  semanticsLabel: 'All areas',
                  onTap: onAll,
                )
              : _Medallion(
                  image: AppImages.medallions[(index - 1) % 3],
                  label: area,
                  onTap: () => onArea(area),
                );
          return Entrance.staggered(
            index: index,
            enabled: reveal,
            start: const Duration(milliseconds: 400),
            offset: const Offset(0, 10),
            beginScale: 0.75,
            curve: AppMotion.popCurve,
            child: PressScale(scale: 0.92, child: medallion),
          );
        },
      ),
    );
  }
}

class _Medallion extends StatelessWidget {
  const _Medallion({
    required this.image,
    required this.label,
    required this.onTap,
    this.semanticsLabel,
  });

  final String image;
  final String label;
  final String? semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel ?? label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 76,
          child: Column(
            children: [
              const SizedBox(height: 2),
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.maroonInk.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    image,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onMaroon,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Popular Areas" tiles on Home: a representative image and the area name.
class PopularAreaRow extends StatelessWidget {
  const PopularAreaRow({
    super.key,
    required this.areas,
    required this.onArea,
    this.padding = EdgeInsets.zero,
    this.reveal = true,
  });

  final List<String> areas;
  final ValueChanged<String> onArea;
  final EdgeInsets padding;

  /// Slides the tiles in one after another.
  final bool reveal;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: areas.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final area = areas[index];
          final tile = Semantics(
            button: true,
            label: area,
            excludeSemantics: true,
            child: InkWell(
              onTap: () => onArea(area),
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 88,
                child: Column(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          AppImages.areaTiles[index %
                              AppImages.areaTiles.length],
                          width: 88,
                          height: 74,
                          fit: BoxFit.cover,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      area,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(color: AppColors.ink),
                    ),
                  ],
                ),
              ),
            ),
          );
          return Entrance.staggered(
            index: index,
            enabled: reveal,
            start: const Duration(milliseconds: 700),
            offset: const Offset(24, 0),
            child: PressScale(child: tile),
          );
        },
      ),
    );
  }
}
