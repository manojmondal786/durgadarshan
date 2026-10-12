import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';

import '../state/app_scope.dart';
import '../state/browse_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_images.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive.dart';
import 'favourites_screen.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'pandal_list_screen.dart';

/// Top-level tabs: a maroon bottom navigation bar on phones, a rail on wide
/// screens.
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.mapTileProvider});

  /// Passed to [MapScreen]; see [MapScreen.tileProvider].
  final TileProvider? mapTileProvider;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  static const _homeTab = 0;
  static const _pandalsTab = 1;
  static const _mapTab = 2;
  static const _favouritesTab = 3;

  int _index = _homeTab;

  /// The map is only built once opened, so no tiles are fetched until the
  /// user actually looks at it.
  bool _mapOpened = false;

  /// Fades the newly selected tab in.
  late final _tabFade = AnimationController(
    vsync: this,
    duration: AppMotion.standard,
    value: 1,
  );
  late final _tabOpacity = CurvedAnimation(
    parent: _tabFade,
    curve: AppMotion.standardCurve,
  );
  late final _tabRise = Tween(
    begin: const Offset(0, 0.015),
    end: Offset.zero,
  ).animate(_tabOpacity);

  void _select(int index) {
    if (index != _index && !AppMotion.reduced(context)) {
      _tabFade.forward(from: 0);
    }
    setState(() {
      _index = index;
      if (index == _mapTab) _mapOpened = true;
    });
  }

  @override
  void dispose() {
    _tabOpacity.dispose();
    _tabFade.dispose();
    super.dispose();
  }

  /// Opens the Pandals tab after resetting filters and applying [configure].
  void _openList(
    BrowseController browse, [
    void Function(BrowseController browse)? configure,
  ]) {
    browse.clear();
    configure?.call(browse);
    _select(_pandalsTab);
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final browse = scope.browse;
    final tabs = IndexedStack(
      index: _index,
      children: [
        HomeScreen(
          onSearch: (query) => _openList(browse, (b) => b.query = query),
          onAreaSelected: (area) => _openList(browse, (b) => b.area = area),
          onSeeAll: () => _openList(browse),
          onExploreMap: () => _select(_mapTab),
          onOpenFavourites: () => _select(_favouritesTab),
          onShowParking: () {
            scope.parking.requestFocus();
            _select(_mapTab);
          },
        ),
        PandalListScreen(onBack: () => _select(_homeTab)),
        if (_mapOpened)
          MapScreen(tileProvider: widget.mapTileProvider)
        else
          const SizedBox.shrink(),
        FavouritesScreen(onBrowse: () => _openList(browse)),
      ],
    );
    final body = FadeTransition(
      opacity: _tabOpacity,
      child: SlideTransition(position: _tabRise, child: tabs),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlay,
      child: ListenableBuilder(
        listenable: scope.favourites,
        builder: (context, _) {
          final destinations = _destinations(scope.favourites.ids.length);
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= Breakpoints.expanded) {
                return Scaffold(
                  body: Row(
                    children: [
                      DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: AppColors.navGradient,
                        ),
                        child: NavigationRail(
                          selectedIndex: _index,
                          onDestinationSelected: _select,
                          labelType: NavigationRailLabelType.all,
                          groupAlignment: -0.85,
                          leading: const Padding(
                            padding: EdgeInsets.only(top: 12, bottom: 8),
                            child: _Emblem(),
                          ),
                          destinations: [
                            for (final d in destinations)
                              NavigationRailDestination(
                                icon: d.icon,
                                selectedIcon: d.selectedIcon,
                                label: Text(d.label),
                              ),
                          ],
                        ),
                      ),
                      Expanded(child: body),
                    ],
                  ),
                );
              }

              return Scaffold(
                body: body,
                bottomNavigationBar: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.navGradient,
                    border: Border(
                      top: BorderSide(
                        color: AppColors.goldBright.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  child: NavigationBar(
                    selectedIndex: _index,
                    onDestinationSelected: _select,
                    destinations: [
                      for (final d in destinations)
                        NavigationDestination(
                          icon: d.icon,
                          selectedIcon: d.selectedIcon,
                          label: d.label,
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

typedef _Destination = ({Widget icon, Widget selectedIcon, String label});

List<_Destination> _destinations(int favouriteCount) {
  Widget counted(IconData icon) => Badge(
    isLabelVisible: favouriteCount > 0,
    label: Text('$favouriteCount'),
    child: Icon(icon),
  );

  return [
    (
      icon: const Icon(Icons.home_outlined),
      selectedIcon: const Icon(Icons.home_rounded),
      label: 'Home',
    ),
    (
      icon: const Icon(Icons.temple_hindu_outlined),
      selectedIcon: const Icon(Icons.temple_hindu),
      label: 'Pandals',
    ),
    (
      icon: const Icon(Icons.map_outlined),
      selectedIcon: const Icon(Icons.map_rounded),
      label: 'Map',
    ),
    (
      icon: counted(Icons.favorite_border_rounded),
      selectedIcon: counted(Icons.favorite_rounded),
      label: 'Favourites',
    ),
  ];
}

/// The gold temple medallion from the redesign, atop the navigation rail.
class _Emblem extends StatelessWidget {
  const _Emblem();

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        AppImages.medallionAll,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
      ),
    );
  }
}
