import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/pandal_repository.dart';
import '../models/pandal.dart';
import '../state/app_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/area_shortcuts.dart';
import '../widgets/darshan_progress_card.dart';
import '../widgets/explore_map_card.dart';
import '../widgets/festive_hero.dart';
import '../widgets/motion/entrance.dart';
import '../widgets/motion/first_reveal.dart';
import '../widgets/motion/press_scale.dart';
import '../widgets/nearby_alerts_card.dart';
import '../widgets/ornaments.dart';
import '../widgets/pandal_cards.dart';
import '../widgets/pandal_search_field.dart';
import '../widgets/parking_card.dart';
import '../widgets/responsive.dart';
import '../widgets/section_header.dart';
import 'darshan_tracker_screen.dart';
import 'pandal_details_screen.dart';

/// How many areas the "Popular Areas" row shows.
const _popularAreaCount = 8;

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onSearch,
    required this.onAreaSelected,
    required this.onSeeAll,
    required this.onExploreMap,
    required this.onOpenFavourites,
    required this.onShowParking,
  });

  final ValueChanged<String> onSearch;
  final ValueChanged<String> onAreaSelected;
  final VoidCallback onSeeAll;
  final VoidCallback onExploreMap;
  final VoidCallback onOpenFavourites;

  /// Opens the Map tab on the saved parking spot.
  final VoidCallback onShowParking;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with FirstReveal {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final repository = scope.repository;
    final featured = repository.featured;
    final areas = repository.areasByPandalCount;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: FestiveHero(
              reveal: revealing,
              onFavourites: widget.onOpenFavourites,
              searchField: PandalSearchField(
                controller: _search,
                onSubmitted: widget.onSearch,
              ),
              shortcuts: AreaShortcutBar(
                reveal: revealing,
                areas: areas,
                onAll: widget.onSeeAll,
                onArea: widget.onAreaSelected,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _Section(
                  title: 'Explore Pandals',
                  onSeeAll: widget.onSeeAll,
                  child: _FeaturedCarousel(
                    pandals: featured,
                    reveal: revealing,
                  ),
                ),
                ContentWidth(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                    child: Entrance(
                      enabled: revealing,
                      delay: const Duration(milliseconds: 600),
                      offset: const Offset(0, 20),
                      child: PressScale(
                        child: ListenableBuilder(
                          listenable: scope.visits,
                          builder: (context, _) => DarshanProgressCard(
                            visited: scope.visits.count,
                            total: repository.pandals.length,
                            onOpen: () => DarshanTrackerScreen.open(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                ContentWidth(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                    child: Entrance(
                      enabled: revealing,
                      delay: const Duration(milliseconds: 625),
                      offset: const Offset(0, 20),
                      child: ParkingCard(onShowOnMap: widget.onShowParking),
                    ),
                  ),
                ),
                ContentWidth(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                    child: Entrance(
                      enabled: revealing,
                      delay: const Duration(milliseconds: 650),
                      offset: const Offset(0, 20),
                      child: PressScale(
                        child: ExploreMapCard(
                          subtitle: _mapSubtitle(repository),
                          onExplore: widget.onExploreMap,
                        ),
                      ),
                    ),
                  ),
                ),
                _Section(
                  title: 'Popular Areas',
                  onSeeAll: widget.onSeeAll,
                  child: PopularAreaRow(
                    reveal: revealing,
                    areas: areas.take(_popularAreaCount).toList(),
                    onArea: widget.onAreaSelected,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
                // Web apps can't follow the user's location in the
                // background, and an iPhone barely lets them notify, so the
                // web version (used on iPhones) leaves alerts out.
                if (!kIsWeb)
                  ContentWidth(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: NearbyAlertsCard(controller: scope.nearbyAlerts),
                    ),
                  ),
                const SizedBox(height: 28),
                const _Footer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _mapSubtitle(PandalRepository repository) {
    final pinned = repository.mappable.length;
    final total = repository.pandals.length;
    if (pinned == 0) return 'Ahmedabad and nearby areas';
    if (pinned == total) return 'Find all pandal locations';
    return '$pinned of $total pandals on the map';
  }
}

/// A titled Home section with a "See All" action, aligned to the content
/// column.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.onSeeAll,
    required this.child,
  });

  final String title;
  final VoidCallback onSeeAll;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ContentWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
            child: SectionHeader(
              title: title,
              actionLabel: 'See All',
              onAction: onSeeAll,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _FeaturedCarousel extends StatelessWidget {
  const _FeaturedCarousel({required this.pandals, required this.reveal});

  final List<Pandal> pandals;

  /// Slides the first cards in one after another.
  final bool reveal;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // About two cards across on phones, more on wider screens.
        final cardWidth = math.min(
          230.0,
          math.max(176.0, (constraints.maxWidth - 46) / 1.9),
        );
        return SizedBox(
          height: cardWidth * 0.62 + 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
            itemCount: pandals.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final pandal = pandals[index];
              return Entrance.staggered(
                index: index,
                enabled: reveal,
                start: const Duration(milliseconds: 500),
                offset: const Offset(36, 0),
                child: FeaturedPandalCard(
                  pandal: pandal,
                  width: cardWidth,
                  onTap: () => PandalDetailsScreen.open(context, pandal),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 0, 40, 28),
      child: Column(
        children: [
          const OrnamentalDivider(),
          const SizedBox(height: 10),
          Text(
            'জয় মা দুর্গা',
            semanticsLabel: 'Joy Maa Durga',
            style: AppTypography.bengali(fontSize: 18, color: AppColors.maroon),
          ),
          const SizedBox(height: 4),
          Text(
            'Source: List of Ahmedabad Durga Puja 2026',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}
