import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Ivory search pill for maroon headers.
class PandalSearchField extends StatelessWidget {
  const PandalSearchField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onSubmitted,
    this.hintText = 'Search pandals, areas or city…',
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.maroonInk.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => TextField(
          controller: controller,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            isDense: true,
            hintText: hintText,
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.search_rounded),
            ),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      controller.clear();
                      onChanged?.call('');
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
