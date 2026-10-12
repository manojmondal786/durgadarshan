import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/motion/page_transition.dart';
import 'app_colors.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  /// Light status bar icons over maroon headers, maroon navigation bar below.
  static const systemOverlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFF55060D),
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.maroon,
      primary: AppColors.maroon,
      onPrimary: AppColors.onMaroon,
      primaryContainer: const Color(0xFFF7E1DC),
      onPrimaryContainer: AppColors.maroonDeep,
      secondary: AppColors.gold,
      onSecondary: AppColors.maroonDeep,
      secondaryContainer: AppColors.goldLight,
      onSecondaryContainer: AppColors.maroonDeep,
      tertiary: AppColors.terracotta,
      onTertiary: Colors.white,
      surface: AppColors.ivory,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.inkMuted,
      surfaceContainerLowest: AppColors.card,
      surfaceContainerLow: const Color(0xFFFFF3E2),
      surfaceContainer: AppColors.cream,
      surfaceContainerHigh: const Color(0xFFF7E3C4),
      surfaceContainerHighest: const Color(0xFFF2DCB8),
      outline: AppColors.outlineStrong,
      outlineVariant: AppColors.outline,
    );

    final base = ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.ivory,
    );
    final textTheme = AppTypography.apply(base.textTheme);

    const pillButton = StadiumBorder();
    const buttonPadding = EdgeInsets.symmetric(horizontal: 22, vertical: 15);
    final navLabel = textTheme.labelMedium?.copyWith(fontSize: 12);

    return base.copyWith(
      textTheme: textTheme,
      // iOS keeps its own transition so swipe-back still works.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FestivePageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: FestivePageTransitionsBuilder(),
          TargetPlatform.linux: FestivePageTransitionsBuilder(),
          TargetPlatform.windows: FestivePageTransitionsBuilder(),
          TargetPlatform.fuchsia: FestivePageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarThemeData(
        backgroundColor: AppColors.maroon,
        foregroundColor: AppColors.onMaroon,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: systemOverlay,
        titleTextStyle: AppTypography.heading(
          fontSize: 20,
          color: AppColors.onMaroon,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: AppColors.card,
        hintStyle: textTheme.bodyLarge?.copyWith(color: AppColors.inkMuted),
        prefixIconColor: AppColors.ink,
        suffixIconColor: AppColors.inkMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.maroon,
          foregroundColor: AppColors.onMaroon,
          padding: buttonPadding,
          shape: pillButton,
          textStyle: textTheme.titleSmall?.copyWith(fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.maroon,
          padding: buttonPadding,
          shape: pillButton,
          side: const BorderSide(color: AppColors.maroon, width: 1.3),
          textStyle: textTheme.titleSmall?.copyWith(fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.maroonDeep,
          textStyle: textTheme.titleSmall,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.goldBright
              : AppColors.card,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.maroon
              : AppColors.outlineStrong,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      // The bar sits on a maroon gradient drawn by the app shell.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.goldBright.withValues(alpha: 0.16),
        elevation: 0,
        height: 66,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 25,
            color: states.contains(WidgetState.selected)
                ? AppColors.goldBright
                : AppColors.onMaroonMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => navLabel?.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppColors.goldBright
                : AppColors.onMaroonMuted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: AppColors.goldBright.withValues(alpha: 0.16),
        selectedIconTheme: const IconThemeData(color: AppColors.goldBright),
        unselectedIconTheme: const IconThemeData(
          color: AppColors.onMaroonMuted,
        ),
        selectedLabelTextStyle: navLabel?.copyWith(
          color: AppColors.goldBright,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: navLabel?.copyWith(
          color: AppColors.onMaroonMuted,
        ),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: AppColors.goldBright,
        textColor: AppColors.maroonDeep,
        textStyle: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.maroonDeep,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.onMaroon,
        ),
        actionTextColor: AppColors.goldLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.outline,
        thickness: 1,
        space: 1,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.maroonDeep,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: AppColors.onMaroon),
      ),
    );
  }
}
