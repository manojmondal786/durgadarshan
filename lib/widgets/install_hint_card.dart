import 'package:flutter/material.dart';

import '../data/app_links.dart';
import '../services/external_maps.dart';
import '../services/install_target.dart';
import '../state/install_hint_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Shown at the top of Home when the web version is open in a phone's
/// browser: how to add it to an iPhone's Home Screen (iPhones never offer an
/// install popup), or a download of the full Android app.
class InstallHintCard extends StatelessWidget {
  const InstallHintCard({super.key, required this.controller});

  final InstallHintController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => switch (controller.target) {
        null => const SizedBox.shrink(),
        final target => Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: _Card(target: target, onDismiss: controller.dismiss),
        ),
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.target, required this.onDismiss});

  final InstallTarget target;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final body = textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted);
    final strong = body?.copyWith(
      color: AppColors.maroonDeep,
      fontWeight: FontWeight.w700,
    );
    final ios = target == InstallTarget.iosHomeScreen;

    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.goldLight, width: 1.4),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.headerGradient,
              ),
              child: Icon(
                ios
                    ? Icons.add_to_home_screen_rounded
                    : Icons.install_mobile_rounded,
                color: AppColors.goldBright,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ios
                        ? 'Add the app to your Home Screen'
                        : 'Get the Android app',
                    style: AppTypography.heading(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  if (ios)
                    Text.rich(
                      TextSpan(
                        style: body,
                        children: [
                          const TextSpan(text: 'Tap '),
                          const WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Icon(
                              Icons.ios_share_rounded,
                              size: 18,
                              color: AppColors.maroon,
                            ),
                          ),
                          TextSpan(text: ' Share', style: strong),
                          const TextSpan(text: ', then '),
                          TextSpan(text: 'Add to Home Screen', style: strong),
                          const TextSpan(
                            text:
                                '. It then opens full screen like an app, '
                                'and keeps your saved visits safe.',
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Text(
                      'The full app also alerts you near pandals. Free, '
                      '38 MB.',
                      style: body,
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () =>
                          ExternalMaps.openUrl(AppLinks.androidApk),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Download the app'),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Close',
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded, color: AppColors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
