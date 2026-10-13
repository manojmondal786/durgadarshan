import 'package:flutter/material.dart';

import '../models/pandal.dart';
import '../models/visit.dart';
import '../services/external_maps.dart';
import '../state/app_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_images.dart';
import '../theme/app_motion.dart';
import '../theme/app_typography.dart';
import '../widgets/about_pandal_card.dart';
import '../widgets/address_search_sheet.dart';
import '../widgets/faded_image.dart';
import '../widgets/favourite_button.dart';
import '../widgets/info_tile.dart';
import '../widgets/motion/entrance.dart';
import '../widgets/pandal_artwork.dart';
import '../widgets/pandal_cards.dart';
import '../widgets/responsive.dart';
import '../widgets/star_rating.dart';
import '../widgets/visit_sheet.dart';
import '../widgets/visiting_hours_card.dart';

class PandalDetailsScreen extends StatelessWidget {
  const PandalDetailsScreen({super.key, required this.pandal});

  final Pandal pandal;

  static Route<void> route(Pandal pandal) => MaterialPageRoute<void>(
    builder: (_) => PandalDetailsScreen(pandal: pandal),
  );

  static Future<void> open(BuildContext context, Pandal pandal) =>
      Navigator.of(context).push(route(pandal));

  /// Gentle hints under the address where the poster doubts the venue or
  /// the pin marks only the area. The poster's own caution wording stays in
  /// the data file.
  @visibleForTesting
  static String? addressCaption(Pandal pandal) {
    final venues = pandal.listedVenues;
    final lines = [
      if (venues.length > 1)
        'Listed venues: ${venues.join(' or ')}.'
      else if (pandal.venueNeedsChecking)
        'Venue as listed by the organisers. Please check before you travel.',
      if (pandal.pinShowsAreaOnly)
        'Map pin shows the area. Use the address to find the venue.',
    ];
    return lines.isEmpty ? null : lines.join('\n');
  }

  /// Lets each block of the page rise in shortly after the one above, as
  /// the page arrives. Spacers stay put.
  static List<Widget> _riseInTurn(List<Widget> children) {
    var index = 0;
    return [
      for (final child in children)
        if (child is SizedBox)
          child
        else
          Entrance.staggered(
            index: index++,
            start: const Duration(milliseconds: 140),
            offset: const Offset(0, 18),
            child: child,
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final address = pandal.address;
    final width = MediaQuery.sizeOf(context).width;
    final expandedHeight = width >= Breakpoints.expanded ? 360.0 : 250.0;

    // A local messenger keeps the maps notice on this page instead of
    // following the user back to the tabs.
    return ScaffoldMessenger(
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              stretch: true,
              expandedHeight: expandedHeight,
              automaticallyImplyLeading: false,
              leading: IconButton(
                tooltip: 'Back',
                color: AppColors.onMaroon,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FavouriteButton(pandal: pandal, overlay: true),
                ),
              ],
              flexibleSpace: _CollapsingArtwork(
                pandal: pandal,
                expandedHeight: expandedHeight,
              ),
            ),
            SliverToBoxAdapter(
              child: ContentWidth(
                maxWidth: 760,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _riseInTurn([
                      Semantics(
                        header: true,
                        child: Text(
                          pandal.name,
                          style: AppTypography.heading(
                            fontSize: 24,
                            color: AppColors.maroon,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      PandalMetaRow(
                        icon: Icons.location_on_outlined,
                        text: pandal.area == pandal.city
                            ? pandal.area
                            : '${pandal.area}, ${pandal.city}',
                      ),
                      const SizedBox(height: 14),
                      const Divider(),
                      const SizedBox(height: 6),
                      InfoTile(
                        icon: Icons.location_on_outlined,
                        label: 'Address',
                        value: address ?? 'Address not listed',
                        isPlaceholder: address == null,
                        caption: addressCaption(pandal),
                      ),
                      const SizedBox(height: 8),
                      VisitingHoursCard(pandal: pandal),
                      const SizedBox(height: 16),
                      AboutPandalCard(description: pandal.description),
                      if (pandal.notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _NotesCard(notes: pandal.notes),
                      ],
                      const SizedBox(height: 16),
                      _DarshanCard(pandal: pandal),
                      const SizedBox(height: 22),
                      _Actions(pandal: pandal),
                    ]),
                  ),
                ),
              ),
            ),
            // Temple skyline from the redesign, kept at the bottom of the
            // page even when the content is short.
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: width.clamp(0, 760) * 152 / 1052,
                    child: const FadedImage(
                      asset: AppImages.detailsFooter,
                      alignment: Alignment.bottomCenter,
                      fadeTop: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Artwork that fills the app bar when expanded and fades to maroon, with
/// the pandal name appearing, as it collapses.
class _CollapsingArtwork extends StatelessWidget {
  const _CollapsingArtwork({
    required this.pandal,
    required this.expandedHeight,
  });

  final Pandal pandal;
  final double expandedHeight;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final collapsedHeight = kToolbarHeight + topInset;
    final number = pandal.posterNumber;

    return LayoutBuilder(
      builder: (context, constraints) {
        final range = expandedHeight + topInset - collapsedHeight;
        final expandedFraction =
            ((constraints.maxHeight - collapsedHeight) / range).clamp(0.0, 1.0);
        final titleOpacity = (1 - expandedFraction * 4).clamp(0.0, 1.0);
        final showOverlays = expandedFraction > 0.6;

        return Stack(
          fit: StackFit.expand,
          children: [
            // The image settles from a slight zoom as the page opens.
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.08, end: 1),
              duration: AppMotion.duration(
                context,
                const Duration(milliseconds: 900),
              ),
              curve: AppMotion.standardCurve,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: PandalArtwork(
                pandal: pandal,
                representativeAsset: AppImages.detailsHeader,
              ),
            ),
            // Keeps the status bar and buttons legible over bright images.
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [Color(0x80000000), Color(0x00000000)],
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: ColoredBox(
                color: AppColors.maroon.withValues(
                  alpha: (1 - expandedFraction).clamp(0.0, 1.0),
                ),
              ),
            ),
            if (showOverlays && number != null)
              Positioned(
                left: 16,
                bottom: 14,
                child: PosterNumberBadge(number: number, onImage: true),
              ),
            if (showOverlays && PandalArtwork.isRepresentative(pandal))
              const Positioned(
                right: 14,
                bottom: 16,
                child: RepresentativeImageTag(),
              ),
            Positioned(
              left: 64,
              right: 72,
              top: topInset,
              height: kToolbarHeight,
              child: IgnorePointer(
                child: Opacity(
                  opacity: titleOpacity,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      pandal.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).appBarTheme.titleTextStyle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Notes carried over from the source list, e.g. timing instructions.
class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes});

  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.terracotta,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: AppColors.cream,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notes from the list',
                  style: AppTypography.heading(fontSize: 16),
                ),
                for (final note in notes)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      note,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.inkMuted,
                      ),
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

/// The user's own darshan record for this pandal: a prompt to mark it as
/// visited, or when they visited with their rating and note.
class _DarshanCard extends StatelessWidget {
  const _DarshanCard({required this.pandal});

  final Pandal pandal;

  Future<void> _edit(BuildContext context) async {
    final visits = AppScope.of(context).visits;
    final before = visits.visitOf(pandal.id);
    final outcome = await VisitSheet.show(
      context,
      pandal: pandal,
      visits: visits,
    );
    if (outcome != VisitSheetOutcome.removed || before == null) return;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Visit removed.'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => visits.save(before),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final textTheme = Theme.of(context).textTheme;
    final total = scope.repository.pandals.length;

    return ListenableBuilder(
      listenable: scope.visits,
      builder: (context, _) {
        final visit = scope.visits.visitOf(pandal.id);
        final rating = visit?.rating;
        final note = visit?.note;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 10),
          decoration: BoxDecoration(
            color: visit == null ? AppColors.card : AppColors.cream,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: visit == null ? AppColors.outline : AppColors.goldLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: visit == null ? null : AppColors.goldGradient,
                      color: visit == null ? AppColors.ivory : null,
                      border: visit == null
                          ? Border.all(color: AppColors.outlineStrong)
                          : null,
                    ),
                    child: Icon(
                      visit == null
                          ? Icons.check_rounded
                          : Icons.check_circle_rounded,
                      color: visit == null
                          ? AppColors.inkMuted
                          : AppColors.maroonDeep,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visit == null ? 'Been here?' : 'Visited',
                          style: AppTypography.heading(fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          visit == null
                              ? 'Mark your darshan to track your progress '
                                    'through all $total pandals.'
                              : formatVisitDateTime(visit.visitedAt),
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.inkMuted,
                          ),
                        ),
                        if (rating != null) ...[
                          const SizedBox(height: 4),
                          StarRating(rating: rating, size: 18),
                        ],
                        if (note != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            note,
                            style: textTheme.bodyMedium?.copyWith(
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
              Align(
                alignment: Alignment.centerRight,
                child: visit == null
                    ? TextButton.icon(
                        onPressed: () => _edit(context),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Mark as visited'),
                      )
                    : TextButton.icon(
                        onPressed: () => _edit(context),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit visit'),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Maps and favourite actions, full width as in the redesign.
class _Actions extends StatelessWidget {
  const _Actions({required this.pandal});

  final Pandal pandal;

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // Pinned pandals open at their coordinates. Any without a pin can search
  // their address instead.
  Future<void> _openInMaps(BuildContext context) async {
    if (pandal.hasVerifiedLocation) {
      return _launch(context, ExternalMaps.linkFor(pandal));
    }
    final queries = ExternalMaps.addressSearchQueries(pandal);
    if (queries.isEmpty) {
      return _showMessage(
        context,
        'There’s no address or map location for this pandal yet.',
      );
    }
    await AddressSearchSheet.show(
      context,
      pandal: pandal,
      queries: queries,
      onSearch: (query) => _launch(context, ExternalMaps.searchFor(query)),
    );
  }

  Future<void> _launch(BuildContext context, MapsLink link) async {
    final opened = await ExternalMaps.open(link);
    if (!opened && context.mounted) {
      _showMessage(context, 'Couldn’t open a maps app.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final favourites = AppScope.of(context).favourites;
    final Widget mapsButton;
    if (pandal.hasVerifiedLocation) {
      mapsButton = FilledButton.icon(
        onPressed: () => _openInMaps(context),
        icon: const Icon(Icons.open_in_new_rounded),
        label: const Text('Open in Maps'),
      );
    } else if (pandal.address != null) {
      // Secondary styling: a search, not a confirmed place.
      mapsButton = FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.goldLight,
          foregroundColor: AppColors.maroonDeep,
        ),
        onPressed: () => _openInMaps(context),
        icon: const Icon(Icons.travel_explore_rounded),
        label: const Text('Search in Maps'),
      );
    } else {
      // Looks unavailable, but still explains why on tap.
      mapsButton = FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.outline,
          foregroundColor: AppColors.inkMuted,
        ),
        onPressed: () => _openInMaps(context),
        icon: const Icon(Icons.lock_outline_rounded),
        label: const Text('Open in Maps'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        mapsButton,
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: favourites,
          builder: (context, _) {
            final isFavourite = favourites.isFavourite(pandal.id);
            return OutlinedButton.icon(
              onPressed: () => favourites.toggle(pandal.id),
              icon: Icon(
                isFavourite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
              ),
              label: Text(
                isFavourite ? 'Saved to Favourites' : 'Add to Favourites',
              ),
            );
          },
        ),
      ],
    );
  }
}
