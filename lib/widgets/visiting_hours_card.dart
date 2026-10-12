import 'package:flutter/material.dart';

import '../models/pandal.dart';
import '../models/visiting_hours.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Visiting hours on the details screen. Actual hours (from the poster or
/// the organisers) and the tentative planning cutoff look clearly different,
/// and each carries a tag saying where it comes from.
class VisitingHoursCard extends StatelessWidget {
  const VisitingHoursCard({super.key, required this.pandal});

  final Pandal pandal;

  static const estimatedTag = 'Estimated · Not Confirmed';
  static const posterTag = 'Poster Source · Not Independently Confirmed';
  static const organisersTag = 'Confirmed by Organisers';
  static const cutoffDisclaimer =
      'Midnight is a tentative planning cutoff, not a confirmed closing '
      'time. Actual visiting hours may differ. Please confirm before '
      'visiting.';

  /// "Until 12:00 AM (Midnight)", without the "Tentative" suffix.
  static String cutoffLabel(ClockTime cutoff) =>
      'Until ${cutoff.format()}${cutoff.isMidnight ? ' (Midnight)' : ''}';

  static String disclaimerFor(ClockTime cutoff) => cutoff.isMidnight
      ? cutoffDisclaimer
      : cutoffDisclaimer.replaceFirst('Midnight', cutoff.format());

  static String rangeLabel(VisitingSession session) =>
      '${session.start.format()} – ${session.end.format()}';

  @override
  Widget build(BuildContext context) {
    final schedule = pandal.schedule;
    final cutoff = pandal.planningCutoff;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.maroonGradient,
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: AppColors.goldLight,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    'Visiting Hours',
                    style: AppTypography.heading(fontSize: 16.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (schedule != null)
            _ActualHours(schedule: schedule)
          else if (cutoff != null)
            _TentativeCutoff(cutoff: cutoff)
          else
            const _NotAnnounced(),
        ],
      ),
    );
  }
}

class _ActualHours extends StatelessWidget {
  const _ActualHours({required this.schedule});

  final VisitingSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final fromPoster = schedule.source == ScheduleSource.poster;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fromPoster
            ? const _SourceTag(
                label: VisitingHoursCard.posterTag,
                icon: Icons.description_outlined,
                foreground: AppColors.maroon,
                background: AppColors.goldLight,
              )
            : const _SourceTag(
                label: VisitingHoursCard.organisersTag,
                icon: Icons.check_circle_outline_rounded,
                foreground: AppColors.onMaroon,
                background: AppColors.maroon,
              ),
        const SizedBox(height: 8),
        for (final session in schedule.sessions)
          _HoursRow(
            label: session.label,
            value: VisitingHoursCard.rangeLabel(session),
          ),
        for (final event in schedule.events)
          _HoursRow(
            label: event.label,
            value: event.time.format(),
            icon: Icons.local_fire_department_outlined,
          ),
        if (fromPoster) ...[
          const SizedBox(height: 6),
          Text(
            'As printed on the 2026 Ahmedabad Durga Puja list.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.inkMuted),
          ),
        ],
      ],
    );
  }
}

/// One line of actual hours: what on the left, when on the right. The time
/// drops below its label when both don't fit, e.g. with large text.
class _HoursRow extends StatelessWidget {
  const _HoursRow({required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final icon = this.icon;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(top: 1, right: 6),
              child: Icon(icon, size: 18, color: AppColors.marigoldDeep),
            )
          else
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 7, 10, 0),
              child: _Diamond(),
            ),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 2,
              children: [
                Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
                Text(
                  value,
                  style: AppTypography.heading(
                    fontSize: 15,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TentativeCutoff extends StatelessWidget {
  const _TentativeCutoff({required this.cutoff});

  final ClockTime cutoff;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SourceTag(
          label: VisitingHoursCard.estimatedTag,
          icon: Icons.hourglass_empty_rounded,
          foreground: AppColors.vermilion,
          background: AppColors.marigold.withValues(alpha: 0.14),
        ),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: VisitingHoursCard.cutoffLabel(cutoff),
                style: AppTypography.heading(
                  fontSize: 17,
                  color: AppColors.maroon,
                ),
              ),
              TextSpan(
                text: ' — Tentative',
                style: AppTypography.heading(
                  fontSize: 15,
                  color: AppColors.inkMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(10, 9, 12, 9),
          decoration: BoxDecoration(
            color: AppColors.cream.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppColors.terracotta,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  VisitingHoursCard.disclaimerFor(cutoff),
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.ink, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotAnnounced extends StatelessWidget {
  const _NotAnnounced();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Not announced yet',
          style: textTheme.bodyLarge?.copyWith(
            color: AppColors.inkMuted,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Please check with the organisers before visiting.',
          style: textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
        ),
      ],
    );
  }
}

/// Small pill naming where the hours come from.
class _SourceTag extends StatelessWidget {
  const _SourceTag({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: foreground,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Diamond extends StatelessWidget {
  const _Diamond();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.785398, // 45°
      child: Container(width: 6, height: 6, color: AppColors.gold),
    );
  }
}
