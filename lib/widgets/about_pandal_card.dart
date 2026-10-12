import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'ornaments.dart';

/// The About Pandal section on the details screen: a serif heading over a
/// gold ornament, then the description as readable paragraphs.
class AboutPandalCard extends StatelessWidget {
  const AboutPandalCard({super.key, required this.description});

  /// Paragraphs are separated by blank lines. Null shows a placeholder.
  final String? description;

  static const title = 'About this Pandal';
  static const placeholder =
      'More about this pandal — its theme, idol, bhog and cultural '
      'programmes — will be added when it’s available.';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final description = this.description;
    final paragraphs = description == null
        ? const <String>[]
        : [
            for (final paragraph in description.split(RegExp(r'\n\s*\n')))
              if (paragraph.trim().isNotEmpty) paragraph.trim(),
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldLight),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: AppTypography.serif(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: AppColors.maroon,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const OrnamentalDivider(),
          const SizedBox(height: 12),
          if (paragraphs.isEmpty)
            Text(
              placeholder,
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.inkMuted,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            for (final (index, paragraph) in paragraphs.indexed)
              Padding(
                padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
                child: Text(
                  paragraph,
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.ink,
                    fontSize: 15.5,
                    height: 1.6,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
