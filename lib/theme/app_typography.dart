import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography, following the approved redesign: the platform sans-serif for
/// the interface, Playfair Display for the "Durga Darshan" wordmark, and
/// Noto Serif Bengali for Bengali greetings.
abstract final class AppTypography {
  static const serifFamily = 'PlayfairDisplay';
  static const bengaliFamily = 'NotoSerifBengali';

  // Playfair defaults to old-style numerals, where "1" reads like "ı".
  static const _serifFeatures = [FontFeature.liningFigures()];

  static TextStyle serif({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: serifFamily,
      fontFeatures: _serifFeatures,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Bengali text such as "শুভ শারদীয়া". The bundled font covers only the
  /// Bengali block, so keep Latin text in a separate span or widget.
  static TextStyle bengali({double? fontSize, Color? color, double? height}) {
    return TextStyle(
      fontFamily: bengaliFamily,
      fontWeight: FontWeight.w600,
      fontSize: fontSize,
      color: color,
      height: height,
    );
  }

  /// Bold interface headings: screen titles, section titles, pandal names.
  static TextStyle heading({
    double? fontSize,
    Color color = AppColors.ink,
    FontWeight fontWeight = FontWeight.w700,
    double? height,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: 0.1,
    );
  }

  /// Applies weights and the warm ink colour to the whole text theme.
  static TextTheme apply(TextTheme base) {
    return base
        .copyWith(
          displaySmall: base.displaySmall?.copyWith(
            fontFamily: serifFamily,
            fontFeatures: _serifFeatures,
            fontWeight: FontWeight.w600,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          labelLarge: base.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          bodyMedium: base.bodyMedium?.copyWith(height: 1.4),
          bodyLarge: base.bodyLarge?.copyWith(height: 1.45),
        )
        .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);
  }
}
