import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Labelled detail row with an outlined icon, used on the details screen.
class InfoTile extends StatelessWidget {
  const InfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.isPlaceholder = false,
    this.caption,
  });

  final IconData icon;
  final String label;
  final String value;

  /// Styles [value] as a stand-in for missing information.
  final bool isPlaceholder;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final caption = this.caption;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, color: AppColors.maroon, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.heading(fontSize: 16.5)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.inkMuted,
                    fontStyle: isPlaceholder ? FontStyle.italic : null,
                  ),
                ),
                if (caption != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    caption,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.inkMuted.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
