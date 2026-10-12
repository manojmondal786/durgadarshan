import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'responsive.dart';

/// Maroon header for the inner tabs: a centred title between optional
/// leading and trailing buttons, with optional content (search, chips)
/// below. Pair with [IvorySheet] for the rounded content area beneath, on a
/// [AppColors.maroonDeep] scaffold so the sheet's corners show maroon.
class FestiveHeader extends StatelessWidget {
  const FestiveHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    final bottom = this.bottom;

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Column(
        children: [
          SizedBox(height: MediaQuery.paddingOf(context).top),
          ContentWidth(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
              child: Row(
                children: [
                  SizedBox(width: 48, child: leading),
                  Expanded(
                    child: Column(
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.heading(
                              fontSize: 21,
                              color: AppColors.onMaroon,
                            ),
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.goldLight),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: 48, child: trailing),
                ],
              ),
            ),
          ),
          if (bottom != null)
            ContentWidth(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: bottom,
              ),
            ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

/// The ivory content area under a maroon header, with rounded top corners
/// as in the redesign.
class IvorySheet extends StatelessWidget {
  const IvorySheet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: ColoredBox(color: AppColors.ivory, child: child),
    );
  }
}
