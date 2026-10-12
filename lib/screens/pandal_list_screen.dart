import 'package:flutter/material.dart';

import '../data/pandal_repository.dart';
import '../state/app_scope.dart';
import '../state/browse_controller.dart';
import '../state/favourites_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/festive_chip.dart';
import '../widgets/festive_header.dart';
import '../widgets/motion/first_reveal.dart';
import '../widgets/pandal_cards_sliver.dart';
import '../widgets/pandal_search_field.dart';
import '../widgets/responsive.dart';
import 'pandal_details_screen.dart';

/// The pandal list with search and filters.
///
/// Only the parts that depend on a change rebuild: typing updates the
/// results, not the header or chips, and favouriting a pandal only reflows
/// the list when it is filtered to favourites.
class PandalListScreen extends StatefulWidget {
  const PandalListScreen({super.key, this.onBack});

  /// Returns to Home; shows a back arrow in the header when set.
  final VoidCallback? onBack;

  @override
  State<PandalListScreen> createState() => _PandalListScreenState();
}

class _PandalListScreenState extends State<PandalListScreen> {
  final _search = TextEditingController();
  BrowseController? _browse;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final browse = AppScope.of(context).browse;
    if (browse != _browse) {
      _browse?.removeListener(_syncSearchText);
      _browse = browse..addListener(_syncSearchText);
      _syncSearchText();
    }
  }

  /// Mirrors a query set elsewhere (e.g. from Home) into the text field.
  void _syncSearchText() {
    final query = _browse!.query;
    if (_search.text == query) return;
    _search.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
  }

  @override
  void dispose() {
    _browse?.removeListener(_syncSearchText);
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final browse = scope.browse;
    final onBack = widget.onBack;

    return Scaffold(
      backgroundColor: AppColors.maroonDeep,
      body: Column(
        children: [
          FestiveHeader(
            title: 'All Pandals',
            leading: onBack == null
                ? null
                : IconButton(
                    tooltip: 'Back to Home',
                    color: AppColors.onMaroon,
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
            bottom: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: PandalSearchField(
                    controller: _search,
                    onChanged: (value) => browse.query = value,
                  ),
                ),
                const SizedBox(height: 12),
                _FilterChips(browse: browse, areas: scope.repository.areas),
              ],
            ),
          ),
          Expanded(
            child: IvorySheet(
              child: _Results(
                repository: scope.repository,
                browse: browse,
                favourites: scope.favourites,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Area and favourites chips. Rebuilds when those filters change, not on
/// every keystroke in the search field.
class _FilterChips extends StatefulWidget {
  const _FilterChips({required this.browse, required this.areas});

  final BrowseController browse;
  final List<String> areas;

  @override
  State<_FilterChips> createState() => _FilterChipsState();
}

class _FilterChipsState extends State<_FilterChips> {
  late String? _area = widget.browse.area;
  late bool _favouritesOnly = widget.browse.favouritesOnly;

  @override
  void initState() {
    super.initState();
    widget.browse.addListener(_onBrowse);
  }

  @override
  void didUpdateWidget(_FilterChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.browse != oldWidget.browse) {
      oldWidget.browse.removeListener(_onBrowse);
      widget.browse.addListener(_onBrowse);
      _onBrowse();
    }
  }

  void _onBrowse() {
    final browse = widget.browse;
    if (browse.area == _area && browse.favouritesOnly == _favouritesOnly) {
      return;
    }
    setState(() {
      _area = browse.area;
      _favouritesOnly = browse.favouritesOnly;
    });
  }

  @override
  void dispose() {
    widget.browse.removeListener(_onBrowse);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final browse = widget.browse;
    return AreaFilterBar(
      areas: widget.areas,
      selectedArea: _area,
      onAreaSelected: (area) => browse.area = area,
      favouritesOnly: _favouritesOnly,
      onFavouritesOnlyChanged: (value) => browse.favouritesOnly = value,
    );
  }
}

/// The result count and cards. New results rise in when the search or
/// filters change.
class _Results extends StatefulWidget {
  const _Results({
    required this.repository,
    required this.browse,
    required this.favourites,
  });

  final PandalRepository repository;
  final BrowseController browse;
  final FavouritesController favourites;

  @override
  State<_Results> createState() => _ResultsState();
}

class _ResultsState extends State<_Results> with FirstReveal {
  @override
  void initState() {
    super.initState();
    widget.browse.addListener(_onBrowse);
    widget.favourites.addListener(_onFavourites);
  }

  @override
  void didUpdateWidget(_Results oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.browse != oldWidget.browse) {
      oldWidget.browse.removeListener(_onBrowse);
      widget.browse.addListener(_onBrowse);
    }
    if (widget.favourites != oldWidget.favourites) {
      oldWidget.favourites.removeListener(_onFavourites);
      widget.favourites.addListener(_onFavourites);
    }
  }

  void _onBrowse() {
    revealNextFrame();
    setState(() {});
  }

  /// Hearts update themselves; the list only changes when it shows
  /// favourites alone.
  void _onFavourites() {
    if (widget.browse.favouritesOnly) setState(() {});
  }

  @override
  void dispose() {
    widget.browse.removeListener(_onBrowse);
    widget.favourites.removeListener(_onFavourites);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final browse = widget.browse;
    final results = widget.repository.search(
      query: browse.query,
      area: browse.area,
      onlyIds: browse.favouritesOnly ? widget.favourites.ids : null,
    );

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: ContentWidth(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 8, 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      results.length == 1
                          ? '1 pandal'
                          : '${results.length} pandals',
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(color: AppColors.inkMuted),
                    ),
                  ),
                  if (browse.hasFilters)
                    TextButton.icon(
                      onPressed: browse.clear,
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Clear filters'),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (results.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: _emptyState(browse)),
          )
        else
          PandalCardsSliver(
            reveal: revealing,
            pandals: results,
            onOpen: (pandal) => PandalDetailsScreen.open(context, pandal),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  Widget _emptyState(BrowseController browse) {
    if (browse.favouritesOnly && browse.query.isEmpty && browse.area == null) {
      return const EmptyState(
        title: 'No favourites yet',
        message: 'Tap the heart on any pandal to keep it here.',
      );
    }
    return EmptyState(
      title: 'No pandals found',
      message: 'Try another name, or choose a different area.',
      actionLabel: 'Clear filters',
      onAction: browse.clear,
    );
  }
}
