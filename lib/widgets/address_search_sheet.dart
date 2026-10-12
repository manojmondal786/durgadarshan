import 'package:flutter/material.dart';

import '../models/pandal.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'notices.dart';

/// Lets the user search a pandal's address in their maps app when it has no
/// map pin, showing exactly what will be searched.
class AddressSearchSheet extends StatelessWidget {
  const AddressSearchSheet({
    super.key,
    required this.pandal,
    required this.queries,
    required this.onSearch,
  });

  final Pandal pandal;

  /// One search text per possible venue.
  final List<String> queries;
  final ValueChanged<String> onSearch;

  static Future<void> show(
    BuildContext context, {
    required Pandal pandal,
    required List<String> queries,
    required ValueChanged<String> onSearch,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.ivory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AddressSearchSheet(
        pandal: pandal,
        queries: queries,
        onSearch: onSearch,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final multiple = queries.length > 1;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Search in Maps',
                style: AppTypography.serif(fontSize: 22, color: AppColors.ink),
              ),
              const SizedBox(height: 4),
              Text(
                pandal.name,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: 14),
              const InfoNotice(
                icon: Icons.info_outline_rounded,
                message:
                    'Your maps app will search for the address below. Check '
                    'that the result matches before you travel.',
              ),
              if (multiple) ...[
                const SizedBox(height: 14),
                Text(
                  'The poster lists ${queries.length} possible venues. You '
                  'can search for each one.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
              for (var i = 0; i < queries.length; i++) ...[
                const SizedBox(height: 12),
                _QueryCard(
                  label: multiple
                      ? 'VENUE ${i + 1} OF ${queries.length}'
                      : 'SEARCHES FOR',
                  query: queries[i],
                  onSearch: () {
                    Navigator.of(context).pop();
                    onSearch(queries[i]);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QueryCard extends StatelessWidget {
  const _QueryCard({
    required this.label,
    required this.query,
    required this.onSearch,
  });

  final String label;
  final String query;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.goldDeep,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(query, style: textTheme.bodyLarge),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onSearch,
              icon: const Icon(Icons.travel_explore_rounded, size: 18),
              label: const Text('Search in Maps'),
            ),
          ),
        ],
      ),
    );
  }
}
