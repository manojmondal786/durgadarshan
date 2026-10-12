import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pandal.dart';
import '../state/app_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';

/// Heart toggle bound to the shared favourites.
class FavouriteButton extends StatelessWidget {
  const FavouriteButton({
    super.key,
    required this.pandal,
    this.overlay = false,
    this.compact = false,
  });

  final Pandal pandal;

  /// Draws an ivory circular backing so the heart reads over artwork.
  final bool overlay;

  /// Tighter touch padding, for small cards.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final favourites = AppScope.of(context).favourites;
    return ListenableBuilder(
      listenable: favourites,
      builder: (context, _) {
        final isFavourite = favourites.isFavourite(pandal.id);
        final button = IconButton(
          tooltip: isFavourite ? 'Remove from favourites' : 'Add to favourites',
          visualDensity: overlay || compact ? VisualDensity.compact : null,
          onPressed: () {
            HapticFeedback.selectionClick();
            favourites.toggle(pandal.id);
          },
          icon: AnimatedSwitcher(
            duration: AppMotion.duration(context, AppMotion.standard),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: AppMotion.popCurve,
              ),
              child: child,
            ),
            child: Icon(
              isFavourite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              key: ValueKey(isFavourite),
              color: AppColors.maroon,
            ),
          ),
        );
        if (!overlay) return button;
        return Material(
          color: const Color(0xFFF3E3C3),
          shape: const CircleBorder(),
          elevation: 2,
          shadowColor: AppColors.maroonInk.withValues(alpha: 0.4),
          child: button,
        );
      },
    );
  }
}
