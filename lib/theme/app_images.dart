import '../models/pandal.dart';

/// Image assets, all cropped from the approved redesign
/// (design/durga_redesign.png).
abstract final class AppImages {
  static const splashArt = 'assets/images/splash/maa_durga.webp';
  static const splashMarigolds = 'assets/images/splash/marigolds.jpg';

  static const headerMarigolds = 'assets/images/home/header_marigolds.jpg';
  static const headerTemple = 'assets/images/home/header_temple.jpg';
  static const exploreMapDurga = 'assets/images/home/explore_map_durga.jpg';

  /// Gold medallion for the "All" shortcut.
  static const medallionAll = 'assets/images/home/medallion_all.png';

  /// Maroon medallions, cycled across the area shortcuts.
  static const medallions = [
    'assets/images/home/medallion_1.png',
    'assets/images/home/medallion_2.png',
    'assets/images/home/medallion_3.png',
  ];

  static const detailsHeader = 'assets/images/pandals/pandal_13.jpg';
  static const detailsFooter = 'assets/images/details/footer_temples.jpg';

  static const mapMarigolds = 'assets/images/map/marigold_corner.jpg';
  static const durgaEyes = 'assets/images/map/durga_eyes.jpg';

  /// Illustrative pandal images from the redesign. They are not photos of
  /// the listed pandals, so screens that show one large label it as a
  /// representative image.
  static const representativePandals = [
    'assets/images/pandals/pandal_01.jpg',
    'assets/images/pandals/pandal_02.jpg',
    'assets/images/pandals/pandal_03.jpg',
    'assets/images/pandals/pandal_04.jpg',
    'assets/images/pandals/pandal_05.jpg',
    'assets/images/pandals/pandal_06.jpg',
    'assets/images/pandals/pandal_07.jpg',
    'assets/images/pandals/pandal_08.jpg',
    'assets/images/pandals/pandal_09.jpg',
    'assets/images/pandals/pandal_10.jpg',
    'assets/images/pandals/pandal_11.jpg',
    'assets/images/pandals/pandal_12.jpg',
    'assets/images/pandals/pandal_13.jpg',
  ];

  /// The redesign's larger pandal images, for cards shown big enough that
  /// the small ones would look soft.
  static const coverPandals = [
    'assets/images/pandals/pandal_07.jpg',
    'assets/images/pandals/pandal_08.jpg',
    'assets/images/pandals/pandal_13.jpg',
  ];

  /// Representative images for the "Popular areas" tiles.
  static const areaTiles = [
    'assets/images/pandals/pandal_09.jpg',
    'assets/images/pandals/pandal_10.jpg',
    'assets/images/pandals/pandal_11.jpg',
    'assets/images/pandals/pandal_12.jpg',
  ];

  /// Images the tabs show as soon as the app opens (Home, and the pandal
  /// list built alongside it). The splash decodes them while it is up so
  /// they don't pop in afterwards.
  static const shownAtLaunch = [
    headerMarigolds,
    headerTemple,
    exploreMapDurga,
    medallionAll,
    ...medallions,
    ...representativePandals,
  ];

  /// Images only the splash shows, released from memory when it closes.
  static const splashOnly = [splashArt, splashMarigolds];

  /// The representative image for [pandal]: stable for a pandal, following
  /// the poster order so the list opens as in the redesign.
  static String representativeFor(Pandal pandal) {
    final index = (pandal.posterNumber ?? _stableHash(pandal.id)) - 1;
    return representativePandals[index % representativePandals.length];
  }

  /// A larger representative image for [pandal], for the Home carousel.
  static String coverFor(Pandal pandal) {
    final index = (pandal.posterNumber ?? _stableHash(pandal.id)) - 1;
    return coverPandals[index % coverPandals.length];
  }

  // String.hashCode differs between platforms; keep the choice stable.
  static int _stableHash(String value) =>
      value.codeUnits.fold(0, (sum, unit) => (sum * 31 + unit) & 0x7fffffff) +
      1;
}
