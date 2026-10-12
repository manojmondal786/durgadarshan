import 'package:flutter/material.dart';

import '../state/app_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/festive_header.dart';
import '../widgets/pandal_cards_sliver.dart';
import 'pandal_details_screen.dart';

/// The pandals the user has hearted, in list order. Favourites are saved on
/// the device, so they survive restarts.
class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key, required this.onBrowse});

  /// Opens the full pandal list.
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final favourites = scope.favourites;

    return Scaffold(
      backgroundColor: AppColors.maroonDeep,
      body: ListenableBuilder(
        listenable: favourites,
        builder: (context, _) {
          final saved = scope.repository.pandals
              .where((pandal) => favourites.isFavourite(pandal.id))
              .toList();

          return Column(
            children: [
              FestiveHeader(
                title: 'Favourites',
                subtitle: switch (saved.length) {
                  0 => null,
                  1 => '1 saved pandal',
                  final n => '$n saved pandals',
                },
              ),
              Expanded(
                child: IvorySheet(
                  child: saved.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                            child: EmptyState(
                              title: 'No favourites yet',
                              message:
                                  'Tap the heart on any pandal to keep it '
                                  'here.',
                              actionLabel: 'Browse pandals',
                              onAction: onBrowse,
                            ),
                          ),
                        )
                      : CustomScrollView(
                          slivers: [
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 10),
                            ),
                            PandalCardsSliver(
                              pandals: saved,
                              onOpen: (pandal) =>
                                  PandalDetailsScreen.open(context, pandal),
                            ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 20),
                            ),
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
