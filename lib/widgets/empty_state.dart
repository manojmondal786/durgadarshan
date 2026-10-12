import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_images.dart';
import '../theme/app_typography.dart';
import 'faded_image.dart';

/// Centred message with the Durga eyes emblem from the redesign.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final actionLabel = this.actionLabel;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 150,
            height: 96,
            child: FadedImage(
              asset: AppImages.durgaEyes,
              fadeLeft: 0.25,
              fadeRight: 0.25,
              fadeTop: 0.2,
              fadeBottom: 0.25,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTypography.heading(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.inkMuted),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ],
      ),
    );
  }
}
