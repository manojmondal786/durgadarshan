import 'package:flutter/material.dart';

import '../models/pandal.dart';
import 'motion/entrance.dart';
import 'pandal_cards.dart';
import 'responsive.dart';

/// [PandalListCard]s in one column on phones, two on tablets and wide
/// browser windows.
class PandalCardsSliver extends StatelessWidget {
  const PandalCardsSliver({
    super.key,
    required this.pandals,
    required this.onOpen,
    this.reveal = false,
  });

  final List<Pandal> pandals;
  final ValueChanged<Pandal> onOpen;

  /// Rises newly built cards in one after another.
  final bool reveal;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.crossAxisExtent >= Breakpoints.medium
            ? 2
            : 1;
        final rows = (pandals.length / columns).ceil();
        return SliverList.builder(
          itemCount: rows,
          itemBuilder: (context, row) {
            final start = row * columns;
            return ContentWidth(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < columns; i++) ...[
                      if (i > 0) const SizedBox(width: 14),
                      Expanded(
                        child: start + i < pandals.length
                            ? Entrance.staggered(
                                // A card keeps its place if the results
                                // shift; only new ones animate.
                                key: ValueKey(pandals[start + i].id),
                                index: start + i,
                                enabled: reveal,
                                offset: const Offset(0, 22),
                                child: PandalListCard(
                                  pandal: pandals[start + i],
                                  onTap: () => onOpen(pandals[start + i]),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
