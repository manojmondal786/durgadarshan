import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';

/// Pill-shaped filter chip for maroon headers: gold when selected, dark
/// maroon otherwise.
class FestiveChip extends StatelessWidget {
  const FestiveChip({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    final foreground = selected ? AppColors.maroonDeep : AppColors.onMaroon;
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: AppMotion.duration(context, AppMotion.quick),
        curve: AppMotion.standardCurve,
        decoration: ShapeDecoration(
          color: selected ? null : AppColors.maroonInk.withValues(alpha: 0.6),
          gradient: selected ? AppColors.goldGradient : null,
          shape: const StadiumBorder(),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: foreground),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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

/// Horizontally scrolling row of a favourites toggle and area chips.
class AreaFilterBar extends StatelessWidget {
  const AreaFilterBar({
    super.key,
    required this.areas,
    required this.selectedArea,
    required this.onAreaSelected,
    required this.favouritesOnly,
    required this.onFavouritesOnlyChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final List<String> areas;
  final String? selectedArea;
  final ValueChanged<String?> onAreaSelected;
  final bool favouritesOnly;
  final ValueChanged<bool> onFavouritesOnlyChanged;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      FestiveChip(
        label: 'All',
        selected: selectedArea == null,
        onTap: () => onAreaSelected(null),
      ),
      for (final area in areas)
        FestiveChip(
          label: area,
          selected: selectedArea == area,
          onTap: () => onAreaSelected(selectedArea == area ? null : area),
        ),
      FestiveChip(
        label: 'Favourites',
        icon: favouritesOnly
            ? Icons.favorite_rounded
            : Icons.favorite_border_rounded,
        selected: favouritesOnly,
        onTap: () => onFavouritesOnlyChanged(!favouritesOnly),
      ),
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) => chips[index],
      ),
    );
  }
}
