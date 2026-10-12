import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Soft gold banner for context the reader should know before relying on
/// the data or an action.
class InfoNotice extends StatelessWidget {
  const InfoNotice({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldLight),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.goldGradient,
            ),
            child: Icon(icon, size: 18, color: AppColors.maroonDeep),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.inkMuted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
