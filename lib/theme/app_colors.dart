import 'package:flutter/material.dart';

/// Bengali Durga Puja palette taken from the approved redesign
/// (design/durga_redesign.png): deep maroon, antique gold, ivory and
/// marigold orange.
abstract final class AppColors {
  // Maroon — headers, navigation, primary actions.
  static const maroon = Color(0xFF6B0A14);
  static const maroonDeep = Color(0xFF4E070D);
  static const maroonInk = Color(0xFF320407);
  static const maroonLight = Color(0xFF8A1A1F);
  static const vermilion = Color(0xFFB8321F);

  // Antique gold — selected states, badges, accents.
  static const gold = Color(0xFFD9A441);
  static const goldBright = Color(0xFFEEB84E);
  static const goldLight = Color(0xFFF3D597);
  static const goldDeep = Color(0xFF9A6B1E);

  // Marigold — highlights and the poster-number badge.
  static const marigold = Color(0xFFF39C12);
  static const marigoldDeep = Color(0xFFD9730B);
  static const marigoldYellow = Color(0xFFFFC93C);
  static const terracotta = Color(0xFFB4561E);

  // Paper and ink.
  static const ivory = Color(0xFFFAEEDC);
  static const cream = Color(0xFFFDE5BE);
  static const card = Color(0xFFFFF8EC);
  static const ink = Color(0xFF3A1410);
  static const inkMuted = Color(0xFF7A6458);
  static const outline = Color(0xFFEFDCC0);
  static const outlineStrong = Color(0xFFDCC39A);

  /// Text and icons on maroon surfaces.
  static const onMaroon = Color(0xFFFFF8EC);
  static const onMaroonMuted = Color(0xC7FFF8EC);

  /// Screen headers: warm maroon settling into a deep base.
  static const headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF7E1018), maroon, maroonDeep],
    stops: [0, 0.5, 1],
  );

  static const maroonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [maroonDeep, maroon, maroonLight],
    stops: [0, 0.55, 1],
  );

  /// The Explore on Map banner: dark on the artwork side, lighter at the
  /// call to action.
  static const bannerGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF3A0503), Color(0xFF5E0E0A), Color(0xFF6E1610)],
    stops: [0, 0.55, 1],
  );

  static const navGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF6E0812), Color(0xFF55060D)],
  );

  /// Splash background beneath the artwork.
  static const splashBackground = Color(0xFF2A0603);

  static const goldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8DFA0), goldBright, gold],
    stops: [0, 0.5, 1],
  );

  /// Soft warm shadow used for cards so they lift off the ivory background.
  static final List<BoxShadow> cardShadow = [
    BoxShadow(
      color: maroonDeep.withValues(alpha: 0.10),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: maroonDeep.withValues(alpha: 0.05),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];

  /// Deeper shadow for floating controls and maroon cards.
  static final List<BoxShadow> raisedShadow = [
    BoxShadow(
      color: maroonInk.withValues(alpha: 0.25),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];
}
