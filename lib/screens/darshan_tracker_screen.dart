import 'package:flutter/material.dart';

import '../models/pandal.dart';
import '../models/visit.dart';
import '../state/app_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/empty_state.dart';
import '../widgets/festive_header.dart';
import '../widgets/pandal_artwork.dart';
import '../widgets/pandal_cards.dart';
import '../widgets/responsive.dart';
import '../widgets/star_rating.dart';
import 'pandal_details_screen.dart';

/// My Darshan: progress through the listed pandals, the user's visits with
/// their ratings and notes, and the pandals still to visit.
class DarshanTrackerScreen extends StatelessWidget {
  const DarshanTrackerScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const DarshanTrackerScreen()));

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final repository = scope.repository;
    final total = repository.pandals.length;

    return Scaffold(
      backgroundColor: AppColors.maroonDeep,
      body: ListenableBuilder(
        listenable: scope.visits,
        builder: (context, _) {
          final visited = [
            for (final visit in scope.visits.visits)
              if (repository.byId(visit.pandalId) case final pandal?)
                (pandal: pandal, visit: visit),
          ];
          final remaining = [
            for (final pandal in repository.pandals)
              if (!scope.visits.isVisited(pandal.id)) pandal,
          ];
          final count = visited.length;
          void open(Pandal pandal) => PandalDetailsScreen.open(context, pandal);

          return Column(
            children: [
              FestiveHeader(
                title: 'My Darshan',
                subtitle: '$count of $total pandals visited',
                leading: IconButton(
                  tooltip: 'Back',
                  color: AppColors.onMaroon,
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                bottom: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _ProgressBar(visited: count, total: total),
                ),
              ),
              Expanded(
                child: IvorySheet(
                  child: CustomScrollView(
                    slivers: [
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),
                      if (count == 0)
                        const SliverToBoxAdapter(
                          child: EmptyState(
                            title: 'Your darshan starts here',
                            message:
                                'Open any pandal and tap Mark as visited. '
                                'Your visits, ratings and notes are kept '
                                'here, on this phone.',
                          ),
                        )
                      else ...[
                        if (remaining.isEmpty)
                          SliverToBoxAdapter(
                            child: _CompleteBanner(total: total),
                          ),
                        _SectionTitle(title: 'Visited', count: count),
                        SliverList.builder(
                          itemCount: visited.length,
                          itemBuilder: (context, index) {
                            final (:pandal, :visit) = visited[index];
                            return _VisitTile(
                              pandal: pandal,
                              visit: visit,
                              onTap: () => open(pandal),
                            );
                          },
                        ),
                      ],
                      if (remaining.isNotEmpty) ...[
                        _SectionTitle(
                          title: 'Still to visit',
                          count: remaining.length,
                        ),
                        SliverList.builder(
                          itemCount: remaining.length,
                          itemBuilder: (context, index) => _RemainingTile(
                            pandal: remaining[index],
                            onTap: () => open(remaining[index]),
                          ),
                        ),
                      ],
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.visited, required this.total});

  final int visited;
  final int total;

  @override
  Widget build(BuildContext context) {
    // The header's subtitle already reads out the progress.
    return ExcludeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : visited / total,
            minHeight: 10,
            color: AppColors.goldBright,
            backgroundColor: AppColors.maroonInk.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: ContentWidth(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
          child: Semantics(
            header: true,
            child: Text(
              '$title · $count',
              style: AppTypography.heading(fontSize: 17),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown once every listed pandal has been visited.
class _CompleteBanner extends StatelessWidget {
  const _CompleteBanner({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return ContentWidth(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              'You’ve visited all $total pandals!',
              textAlign: TextAlign.center,
              style: AppTypography.heading(
                fontSize: 17,
                color: AppColors.maroonDeep,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'জয় মা দুর্গা',
              semanticsLabel: 'Joy Maa Durga',
              style: AppTypography.bengali(
                fontSize: 18,
                color: AppColors.maroonDeep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One visit: the pandal, when, and the user's rating and note.
class _VisitTile extends StatelessWidget {
  const _VisitTile({
    required this.pandal,
    required this.visit,
    required this.onTap,
  });

  final Pandal pandal;
  final Visit visit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final rating = visit.rating;
    final note = visit.note;

    return ContentWidth(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 5, 16, 5),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox.square(
                    dimension: 60,
                    child: PandalArtwork(
                      pandal: pandal,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pandal.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.heading(fontSize: 15),
                        ),
                        const SizedBox(height: 3),
                        PandalMetaRow(
                          icon: Icons.check_circle_rounded,
                          text: formatVisitDateTime(visit.visitedAt),
                        ),
                        if (rating != null) ...[
                          const SizedBox(height: 4),
                          StarRating(rating: rating),
                        ],
                        if (note != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            note,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.ink,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
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

/// A pandal not visited yet, in poster order.
class _RemainingTile extends StatelessWidget {
  const _RemainingTile({required this.pandal, required this.onTap});

  final Pandal pandal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final number = pandal.posterNumber;
    return ContentWidth(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
          child: Row(
            children: [
              if (number != null) ...[
                PosterNumberBadge(number: number),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pandal.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      pandal.area,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.inkMuted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.maroon),
            ],
          ),
        ),
      ),
    );
  }
}
