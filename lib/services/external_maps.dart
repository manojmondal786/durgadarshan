import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/pandal.dart';

typedef UrlOpener = Future<bool> Function(Uri uri);

/// Where to send the user: a [primary] link and an optional web [fallback]
/// for when no installed app handles the primary one.
@immutable
class MapsLink {
  const MapsLink(this.primary, [this.fallback]);

  final Uri primary;
  final Uri? fallback;
}

/// Hands verified pandal locations, unverified pandals' addresses as a
/// search, and directions back to a parked vehicle to the user's own maps
/// app or website. The app itself calls no routing or geocoding service.
abstract final class ExternalMaps {
  /// Opens a URL outside the app. Tests replace this so nothing launches.
  @visibleForTesting
  static UrlOpener opener = _launchExternally;

  static Future<bool> _launchExternally(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  /// Builds a link that shows [pandal] in a maps app, from where the user can
  /// get directions.
  ///
  /// * Android: a `geo:` URI, so the user's choice of maps app opens.
  /// * iOS: Apple Maps with the pandal as the destination.
  /// * Web and desktop: the OpenStreetMap website (Apple Maps in a browser
  ///   on an iPhone).
  ///
  /// A pin that marks only the area would lead to the neighbourhood centre,
  /// so for those the maps app searches for the name and address near the
  /// pin instead (see [searchFor]).
  ///
  /// Throws an [ArgumentError] unless the pandal has a verified location.
  static MapsLink linkFor(
    Pandal pandal, {
    TargetPlatform? platform,
    bool isWeb = kIsWeb,
  }) {
    if (!pandal.hasVerifiedLocation) {
      throw ArgumentError.value(
        pandal.id,
        'pandal',
        'Only pandals with a verified location can be opened in maps',
      );
    }
    if (pandal.pinShowsAreaOnly) {
      final queries = addressSearchQueries(pandal);
      if (queries.isNotEmpty) {
        return searchFor(
          queries.first,
          near: LatLng(pandal.latitude!, pandal.longitude!),
          platform: platform,
          isWeb: isWeb,
        );
      }
    }
    final lat = pandal.latitude!.toStringAsFixed(6);
    final lng = pandal.longitude!.toStringAsFixed(6);
    final web = openStreetMapUri(lat, lng);
    final target = platform ?? defaultTargetPlatform;
    // On an iPhone the web app opens Apple Maps, as the iOS app does.
    if (isWeb && target != TargetPlatform.iOS) return MapsLink(web);

    switch (target) {
      case TargetPlatform.android:
        // Parentheses would end the geo: label early.
        final label = pandal.name.replaceAll(RegExp(r'[()]'), '');
        return MapsLink(
          Uri.parse('geo:$lat,$lng?q=$lat,$lng(${Uri.encodeComponent(label)})'),
          web,
        );
      case TargetPlatform.iOS:
        return MapsLink(
          Uri.https('maps.apple.com', '/', {
            'daddr': '$lat,$lng',
            'q': pandal.name,
          }),
          web,
        );
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return MapsLink(web);
    }
  }

  /// Search texts for a pandal's poster address: one per alternative venue
  /// (the data separates alternatives with " / "). Each adds the pandal's
  /// name, and the city when the address leaves it out, because many listed
  /// addresses are only landmarks.
  static List<String> addressSearchQueries(Pandal pandal) {
    final address = pandal.address;
    if (address == null) return const [];
    final city = pandal.city.toLowerCase();
    return [
      for (final option in address.split(' / ').map(_trimTrailingPunctuation))
        if (option.isNotEmpty)
          [
            pandal.name,
            option,
            if (!option.toLowerCase().contains(city)) pandal.city,
          ].join(', '),
    ];
  }

  static String _trimTrailingPunctuation(String text) =>
      text.trim().replaceFirst(RegExp(r'[\s.,]+$'), '');

  /// Builds a link that searches for [query] in a maps app: for pandals
  /// without a pin, or whose pin marks only the area. The maps app does the
  /// searching, so its result may not be the pandal. The app itself looks
  /// nothing up.
  ///
  /// [near] makes the maps app search around that point first. Google Maps
  /// links can't take one, so on the web and desktop the query's area and
  /// city have to do.
  ///
  /// * Android: a `geo:` search, so the user's choice of maps app opens.
  /// * iOS: an Apple Maps search.
  /// * Web and desktop: a Google Maps search, which copes better with
  ///   landmark-style addresses than openstreetmap.org's search (Apple Maps
  ///   in a browser on an iPhone).
  static MapsLink searchFor(
    String query, {
    LatLng? near,
    TargetPlatform? platform,
    bool isWeb = kIsWeb,
  }) {
    final web = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': query,
    });
    final target = platform ?? defaultTargetPlatform;
    // On an iPhone the web app opens Apple Maps, as the iOS app does.
    if (isWeb && target != TargetPlatform.iOS) return MapsLink(web);

    final centre = near == null
        ? null
        : '${near.latitude.toStringAsFixed(6)},'
              '${near.longitude.toStringAsFixed(6)}';
    switch (target) {
      case TargetPlatform.android:
        return MapsLink(
          Uri.parse('geo:${centre ?? '0,0'}?q=${Uri.encodeComponent(query)}'),
          web,
        );
      case TargetPlatform.iOS:
        return MapsLink(
          Uri.https('maps.apple.com', '/', {
            'q': query,
            'sll': ?centre,
          }),
          web,
        );
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return MapsLink(web);
    }
  }

  /// Builds a link for walking directions to [destination], e.g. back to
  /// the user's parked vehicle. The maps app plans the route from wherever
  /// the user is; the app itself calls no routing service.
  ///
  /// * Android, web and desktop: Google Maps directions, which open the
  ///   Google Maps app when it's installed and its website otherwise. On
  ///   Android, a `geo:` link to the spot is the fallback.
  /// * iOS, including the web app on an iPhone: Apple Maps directions, with
  ///   the Google Maps website as fallback.
  static MapsLink directionsTo(
    LatLng destination, {
    required String label,
    TargetPlatform? platform,
    bool isWeb = kIsWeb,
  }) {
    final lat = destination.latitude.toStringAsFixed(6);
    final lng = destination.longitude.toStringAsFixed(6);
    final google = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$lat,$lng',
      'travelmode': 'walking',
    });
    final target = platform ?? defaultTargetPlatform;
    // On an iPhone the web app opens Apple Maps, as the iOS app does.
    if (isWeb && target != TargetPlatform.iOS) return MapsLink(google);

    switch (target) {
      case TargetPlatform.android:
        // Parentheses would end the geo: label early.
        final name = label.replaceAll(RegExp(r'[()]'), '');
        return MapsLink(
          google,
          Uri.parse('geo:$lat,$lng?q=$lat,$lng(${Uri.encodeComponent(name)})'),
        );
      case TargetPlatform.iOS:
        return MapsLink(
          Uri.https('maps.apple.com', '/', {
            'daddr': '$lat,$lng',
            'dirflg': 'w',
          }),
          google,
        );
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return MapsLink(google);
    }
  }

  static Uri openStreetMapUri(String lat, String lng) => Uri.https(
    'www.openstreetmap.org',
    '/',
    {'mlat': lat, 'mlon': lng},
  ).replace(fragment: 'map=18/$lat/$lng');

  /// Tries the primary link, then the fallback. Returns whether one opened.
  static Future<bool> open(MapsLink link) async {
    for (final uri in [link.primary, ?link.fallback]) {
      if (await openUrl(uri)) return true;
    }
    return false;
  }

  /// Opens [uri] externally, returning false instead of throwing when no
  /// app or browser can handle it.
  static Future<bool> openUrl(Uri uri) async {
    try {
      return await opener(uri);
    } catch (_) {
      return false;
    }
  }
}
