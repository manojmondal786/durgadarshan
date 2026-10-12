import 'package:flutter/material.dart';

import '../state/nearby_alerts_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Home screen switch for "pandal nearby" notifications.
class NearbyAlertsCard extends StatelessWidget {
  const NearbyAlertsCard({super.key, required this.controller});

  final NearbyAlertsController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final status = controller.status;
        final (String message, bool canOpenSettings) = switch (status) {
          NearbyAlertsStatus.off => (
            'Get a notification when you’re within 3 km of a pandal, while '
                'the app is open or minimised.',
            false,
          ),
          NearbyAlertsStatus.starting => ('Turning on…', false),
          NearbyAlertsStatus.active => (
            'On. You’ll be notified within 3 km of a pandal while the app is '
                'open or minimised.',
            false,
          ),
          NearbyAlertsStatus.notificationsDenied => (
            'Notifications are off for this app. Allow them in Settings to '
                'get alerts.',
            true,
          ),
          NearbyAlertsStatus.locationDenied => (
            'Location access was declined. Turn the switch on to ask again.',
            false,
          ),
          NearbyAlertsStatus.locationDeniedForever => (
            'Location access is blocked. Allow it in Settings to get alerts.',
            true,
          ),
          NearbyAlertsStatus.locationServiceOff => (
            'Location is turned off on this device. Turn it on to get '
                'alerts.',
            true,
          ),
        };

        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppColors.cardShadow,
          ),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.headerGradient,
                        ),
                        child: Icon(
                          controller.isOn
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_none_rounded,
                          color: AppColors.goldBright,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Nearby pandal alerts',
                          style: AppTypography.heading(fontSize: 17),
                        ),
                      ),
                      Switch(
                        value: controller.isOn,
                        onChanged: status == NearbyAlertsStatus.starting
                            ? null
                            : (on) => on
                                  ? controller.enable()
                                  : controller.disable(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      message,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ),
                  if (canOpenSettings)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: controller.openSettings,
                        icon: const Icon(Icons.settings_outlined, size: 18),
                        label: const Text('Open settings'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
