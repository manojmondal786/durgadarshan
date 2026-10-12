import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Home card for My Darshan: a progress ring of pandals visited, opening
/// the tracker.
class DarshanProgressCard extends StatelessWidget {
  const DarshanProgressCard({
    super.key,
    required this.visited,
    required this.total,
    required this.onOpen,
  });

  final int visited;
  final int total;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    final String subtitle;
    if (visited == 0) {
      subtitle = 'Mark pandals as visited and track all $total';
    } else if (visited >= total) {
      subtitle = 'All $total visited. Joy Maa Durga!';
    } else {
      subtitle = '$visited of $total visited · ${total - visited} to go';
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: const BorderSide(color: AppColors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                _ProgressRing(visited: visited, total: total),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Darshan',
                        style: AppTypography.heading(fontSize: 18),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppColors.inkMuted),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.maroon,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.visited, required this.total});

  final int visited;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$visited of $total pandals visited',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: 56,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: total == 0 ? 0 : visited / total,
              strokeWidth: 5,
              strokeCap: StrokeCap.round,
              color: AppColors.maroon,
              backgroundColor: AppColors.outline,
            ),
            Center(
              child: Text(
                '$visited/$total',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.maroon,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
