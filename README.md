# Durga Darshan Ahmedabad

A personal-use Flutter app for visiting Durga Puja pandals in Ahmedabad and
nearby areas.

**Status:** the app lists the 25 pandals from the *List of Ahmedabad Durga Puja
2026* poster (`assets/reference/pandal_list.jpg`), bundled as
`assets/data/pandals.json`. All 25 are pinned on an OpenStreetMap map, and
optional notifications tell you when a pandal is within 3 km while the app is
open or minimised.

There is no backend or account. Favourites, your darshan log, your parking
spot, the alerts switch and which pandals have already alerted today are
saved on the device
(shared preferences), so they survive restarts. Nothing is sent anywhere.

## Design

The interface follows the approved redesign, `design/durga_redesign.png`:
deep maroon, antique gold, ivory and marigold, with a Maa Durga splash, a
festive Home banner, maroon headers over ivory content and a maroon bottom
bar (Home, Pandals, Map, Favourites). Screenshots of the built app are in
`design/screenshots/` (`00_overview.png` puts the five main screens side by
side).

- **Images** in `assets/images/` are cropped from the redesign and enlarged,
  so they look a little soft on high-density screens. Replace a file with a
  sharper version of the same picture at the same path to improve it.
- **Pandal pictures** are illustrative, not photos of the listed pandals. Each
  pandal gets one by its poster number (`AppImages.representativeFor`), and
  the details page labels it *Representative image*. A real photo set in a
  pandal's `image` field replaces it and drops the label.
- **Fonts:** Playfair Display for the "Durga Darshan" wordmark, Noto Serif
  Bengali (subset to the Bengali block) for Bengali greetings, and the
  platform sans-serif for everything else.
- **Motion** (recording: `design/animations/walkthrough.mp4`, stills:
  `design/animations/key_frames.png`):
  - Splash: Maa Durga fades in and settles from a slight zoom, golden embers
    rise from the lamps, the marigolds lift, and the name appears line by
    line. It stays up for at least 2.4 s, then cross-fades into Home.
  - Home: the banner art slides in from the sides, the area medallions pop
    in one by one, and the pandal cards, Explore on Map banner and area tiles
    follow.
  - Tabs fade through; list cards rise in turn when the list opens or the
    search or area filter changes.
  - Pages rise over the previous one (iOS keeps its own transition and
    swipe-back). On the details page the image settles and each block
    follows the one above.
  - Map pins drop in when the map first opens, and the pin preview slides up.
  - Cards, medallions and tiles shrink slightly while pressed.

  Timings and curves live in `AppMotion` (`lib/theme/app_motion.dart`); the
  building blocks (`Entrance`, `PressScale`, the page transition, the
  embers) are in `lib/widgets/motion/`. Every animation runs once and stops,
  and all of it is skipped when the system's "remove animations" setting is
  on.
- Mockup sample data is not used. The app shows the real 25 pandals, no
  verification badges, and the real map pins.

## Run

```sh
flutter pub get

# Chrome
flutter run -d chrome

# Android (emulator or USB device with debugging enabled)
flutter devices
flutter run -d <device-id>
```

## Check

```sh
flutter analyze
flutter test
```

Tests run offline: the map uses fake tiles (`test/helpers/fake_tiles.dart`) and
external links are recorded instead of launched.

## Pandal data

`assets/data/pandals.json` holds a `pandals` list. Each record has:

| Field | Notes |
| --- | --- |
| `id` | Stable kebab-case id; favourites are keyed by it. |
| `posterNumber` | Position on the source poster. |
| `name`, `address` | Transcribed as printed. Alternative venues in `address` are separated by ` / `. |
| `posterAddress` | The full poster address, when `address` holds only the chosen venue (#15, #17). |
| `area`, `city` | Area drives the filter chips. |
| `latitude`, `longitude` | Both null, or both set. Only used once verified. |
| `verificationStatus` | `verified`, `unverified`, `needs_check` or `conflicting`. |
| `timings`, `description`, `image` | Null when unknown; the UI says so. |
| `notes` | Notes shown in the app under "Notes from the list". |
| `posterCautions` | The poster's caution remarks ("Need to check", two venues, …). Kept for reference, never shown in the app. |
| `verification` | Added by the verification tool; see below. |

The `verification` object (absent until the tool first touches a pandal):

| Field | Set by | Meaning |
| --- | --- | --- |
| `coordinatesSource` | `set` | Where the coordinates came from. |
| `coordinatesRecordedOn` | `set` | Date the coordinates were recorded. |
| `coordinatesPrecision` | address lookup | `landmark`, `street` or `area` when a pin came from an address lookup; cleared by `set`. |
| `verifiedOn` | `verify` | Date you confirmed the location. |
| `verificationNote` | `verify` | How you confirmed it. |
| `statusBeforeVerification` | `verify` | The poster status (e.g. `needs_check`), so the flag isn't lost. |

Use `null` for anything unknown rather than guessing. `flutter test` checks
the file's integrity: 25 unique ids, valid fields and statuses, coordinate
pairs in range, a recorded source for any coordinates, and valid coordinates
plus confirmation details for every verified pandal.

## Map

The Map tab uses [flutter_map](https://pub.dev/packages/flutter_map) with
OpenStreetMap tiles. It opens framed around every pin and supports pinch/scroll
zoom, panning, zoom buttons and a reset-view button that re-frames the pins
(rotation is off). Pandals at the same spot share one pin with a count badge.

A pandal gets a pin, and an *Open in Maps* action, when `verificationStatus` is
`verified` **and** it has a valid `latitude` (−90…90) and `longitude`
(−180…180). Coordinates alone are never enough. Use the verification tool below
rather than editing coordinates by hand.

*Open in Maps* hands the location to the user's own maps app: a `geo:` link on
Android, Apple Maps on iOS, and openstreetmap.org on the web and desktop. The
app never calls a routing or geocoding service.

### Where the 25 pins came from

On 2026-10-12, after the owner confirmed the poster addresses, each pandal was
pinned by a one-time lookup of its address with OpenStreetMap's Nominatim
search. The lookup made 82 requests, at most one per second, limited to the
Ahmedabad area.

Few venues are named in OpenStreetMap, so most pins mark the neighbourhood, not
the exact venue. `coordinatesPrecision` records which:

| Precision | Pandals | What the pin marks |
| --- | --- | --- |
| Nearby landmark | #4, #11, #12, #13, #14 | A landmark the address names (e.g. Ghodasar BRTS, Naginawadi, Water Lily Shantigram). |
| Street | #1, #18 | The middle of Airport Road / Sindhu Bhavan Road. |
| Area | the other 18 | The neighbourhood or town centre (e.g. Naroda, Gota, Bavla); #21 is Sector 28. |

Pandals sharing a neighbourhood share a pin: #3 and #5 (Maninagar), #4 and #22
(Ghodasar) and #9 and #10 (Odhav).

To correct a pin once you know the exact spot, run `set <n>` and then
`verify <n>` with the tool. The poster's caution remarks are kept in
`posterCautions`.

### Searching an address without a pin

Pandals without a pin show **Search in Maps** instead. It opens a sheet with
the following:
- a reminder to check the result before travelling;
- the exact text that will be searched: the pandal's name, the poster address,
  and the city if the address leaves it out;
- one search per venue for entries with two possible venues (#15 and #17).

Choosing a search hands that text to the user's maps app:

| Platform | Opens |
| --- | --- |
| Android | `geo:0,0?q=…`, so the user's choice of maps app runs the search. |
| iOS | Apple Maps. |
| Web and desktop | The Google Maps website, which copes better with landmark-style addresses than openstreetmap.org's search. |

The maps app does the searching. The app looks nothing up, stores no
coordinates and adds no pins. Vague addresses such as "Airport road,
Ahmedabad" only lead to the general area.

A search can help you find coordinates for the verification tool. When the
maps app shows the right venue, long-press it to read its coordinates, then
record them with `set <n>`. Confirm the location with the organisers before
running `verify <n>`.

### OpenStreetMap attribution and tile usage

Map data © [OpenStreetMap contributors](https://www.openstreetmap.org/copyright),
available under the Open Database Licence. The map always shows this credit,
and tapping it opens the copyright page.

Tiles come from the public `tile.openstreetmap.org` servers. These are run by
volunteers on donated resources, with no uptime guarantee, under the
[Tile Usage Policy](https://operations.osmfoundation.org/policies/tiles/).
This app tries to be a light, polite user:

- It identifies itself in the tile requests' User-Agent via
  `MapConfig.userAgentPackageName` (`lib/data/map_config.dart`). On the web,
  browsers send their own User-Agent instead.
- It loads tiles only after the Map tab is opened, and only for the visible
  area. It does no prefetching, bulk downloading or offline tile packs.
- It caches tiles on the device (up to 100 MB on Android/iOS), following the
  servers' HTTP cache headers. On the web, the browser cache applies.
- It goes no further than zoom 19, the highest the standard tiles provide, and
  uses the single tile host with no subdomains.
- Tile failures (e.g. offline) show a banner with *Retry* rather than breaking
  the map.

The tile requests identify the app as `com.durgadarshan.ahmedabad`, the same
id as the Android application id and iOS bundle identifier. If the id ever
changes, update all three together (`MapConfig.userAgentPackageName`).

This suits a personal app. If usage grows, consider a commercial or
self-hosted tile provider by changing `MapConfig.osmTileUrl`, since the policy
asks heavy users not to rely on the public servers.

## My Darshan

Track your darshan through all the listed pandals.

- On a pandal's page, **Mark as visited** records the date and time (now by
  default; you can pick an earlier date or time, but not a future one), with
  an optional 1–5 star rating and a note of up to 280 characters. **Edit
  visit** changes it, or removes it with an Undo.
- The **My Darshan** card on Home shows a progress ring (e.g. 3/25) and opens
  the tracker: your visits, newest first, with their ratings and notes, then
  the pandals still to visit in poster order. Visiting all of them is
  celebrated.
- Visited pandals are marked *Visited* in the pandal list and Favourites.
- The log is saved on the device (`AppStorage.visitRecords`); visits for
  pandals no longer listed, and unreadable records, are skipped.

## Parking spot saver

When you park near a pandal, tap **Save My Parking** on Home's *My Parking*
card. Later, **Navigate to my vehicle** walks you back.

- Saving takes one precise GPS fix (asking for "while using the app" location
  if needed) and keeps it on the device with the time. If the fix is rough
  (worse than 50 m), the card says so and suggests updating it in the open.
- The card names the nearest pandal within 1 km, and you can add a note such
  as "Basement 2, pillar 14".
- **Navigate to my vehicle** hands walking directions to your maps app:
  Google Maps on Android and the web (the website if the app isn't
  installed, with a `geo:` link as a last resort on Android) and Apple Maps on
  iOS. The app itself calls no routing service.
- The Map tab shows your vehicle as a car marker. Tap it, or the car button
  in the map controls, for a preview with Navigate. *Show on map* on the card
  opens the map on it.
- **Update spot** asks before replacing a saved spot, so a stray tap can't
  lose the way back. **Clear** forgets it, with Undo.

## Nearby pandal alerts

Turn on **Nearby pandal alerts** on the Home screen to get a notification
when you come within 3 km of a pinned pandal.

- Alerts are notifications only (there is no in-app banner), so the app asks
  for notification permission first, then location. Tapping a notification
  opens the pandal, even if the app had been closed since.
- They work while the app is open or minimised, and stop when it is closed
  (swiped away). Location is "while using the app" only, never "all the
  time": once alerts are on, Android keeps updates coming through a
  foreground service with an ongoing *Watching for nearby pandals*
  notification, and iOS shows its background location indicator.
- Alerts left on come back on at the next launch, without asking for any
  permission. If one has been withdrawn, the card says so.
- Each pandal alerts at most once per day, across restarts. If several
  pandals come within range together, one notification names the nearest
  and counts the rest.
- In Chrome it uses browser notifications.
- While alerts are on, the map shows a "you are here" dot.
- Location uses medium accuracy and updates every 150 m or so to save battery.
  Your position stays on the device and is never sent anywhere.
- Distances are measured to the pins. Most pins mark the neighbourhood (see
  above), so treat "within 3 km" as approximate.

If location is declined, the card says so. If notifications or location are
blocked, or location is switched off, the card offers **Open settings**.

Publishing: Google Play asks apps with a location foreground service to
declare it (with a short video of the feature) in the Play Console, and the
App Store reviews the iOS `location` background mode.

## Verifying pandal locations (developer tool)

`tool/verify_pandals.dart` is a local, command-line-only tool for recording
and confirming pandal coordinates. It lives outside `lib/`, so it is never
part of the app, and it works entirely offline: no geocoding, scraping,
network access or accounts. **You** supply every coordinate.

Run it from the project root:

```sh
dart run tool/verify_pandals.dart help        # list of commands
dart run tool/verify_pandals.dart list        # all 25: number, name, area, address, status, notes, coordinates
dart run tool/verify_pandals.dart review      # verified / candidate / unresolved summary
dart run tool/verify_pandals.dart show 5      # one pandal in full, with a map link to check by eye
dart run tool/verify_pandals.dart set 5       # record candidate coordinates for poster #5
dart run tool/verify_pandals.dart verify 5    # confirm #5 after checking it independently
dart run tool/verify_pandals.dart clear 5     # remove #5's coordinates (and any verification)
```

Add `--file <path>` to work on a different copy of the JSON.

### Workflow

1. **Find coordinates yourself**, for example by visiting the venue, or from a
   map app's "drop pin" feature once you know exactly where the venue is.
2. **Record them as a candidate:** `dart run tool/verify_pandals.dart set <n>`.
   - Enter latitude and longitude in decimal degrees with at least 4 decimal
     places (e.g. `23.022500` and `72.571400`), or paste them as
     `23.022500, 72.571400`.
   - Then enter a source or note saying where they came from, and type `yes` to
     save.
   - Malformed or out-of-range values are rejected and asked for again.
   - Coordinates more than 60 km from Ahmedabad (or apparently swapped) need an
     extra `yes`. A blank answer cancels.
   - **Candidates are hidden in the app.** The pandal keeps its current status
     (including `needs check` / `unclear location`) and does not get a pin.
3. **Independently confirm both** that the venue is at those coordinates **and**
   that this year's pujo is being held there. Phone the organisers, visit, or
   check their latest announcement.
4. **Verify:** `dart run tool/verify_pandals.dart verify <n>`. You must:
   - answer `yes` to "confirmed the venue" and to "confirmed the current event
     location";
   - for pandals the poster flagged (#5, #6, #15, #17, #21), also answer `yes`
     to "resolved that flag";
   - describe how you confirmed it; and
   - type the poster number again.

   Any other answer leaves the pandal as a candidate. The poster status is kept
   in `statusBeforeVerification`, and the notes are untouched.
5. **Check:** `dart run tool/verify_pandals.dart review`, then
   `flutter test`.
6. **Fully restart the app** (not hot reload) to see the new pin, because the
   JSON is a bundled asset.

Replacing a pandal's existing coordinates with `set` asks for confirmation
first. Replacing a verified pandal's coordinates also removes its verified
status, so new coordinates must be verified again.

### Safety

- Every save first copies the current file to
  `assets/data/backups/pandals-YYYYMMDD-HHMMSS.json`. This folder is ignored by
  git and not bundled into the app. To undo a save, copy a backup back over
  `assets/data/pandals.json`.
- The new file is written to a temporary file in the same folder, re-read and
  checked, then renamed over the original in one step, so it is never left
  half-written.
- The tool refuses to save if the file changed since it was read, and refuses
  to work on a file that fails its integrity checks.
- Only the chosen pandal changes; every other field and record is kept as is.

## Web app for iPhone

iPhones can't install the APK, so iPhone users get the web version, hosted
on GitHub Pages at https://manojmondal786.github.io/durgadarshan/ and added
to the Home Screen (Share → Add to Home Screen). iPhones never show an
install popup for websites, so when the web version is open in a phone's
browser, Home shows its own banner: the Add to Home Screen steps on an
iPhone, or a download of the Android app on Android. It hides once the app
is opened from the Home Screen, or after it is closed.

On the web the Nearby alerts card is left out (web apps can't follow the
user's location in the background), and on an iPhone map links open Apple
Maps.

To publish an update, build with the site's path and replace the
`gh-pages` branch's files with `build/web`:

```sh
flutter build web --release --base-href /durgadarshan/
touch build/web/.nojekyll
```

## Release signing

Release builds are signed with the key described in `android/key.properties`,
which is git-ignored along with keystores. Until it exists, release builds
fall back to the debug key and Gradle prints a warning: never publish such a
build.

Create the upload key once, outside the project, and keep a backup of it and
its passwords; without them the app can't be updated on the Play Store:

```sh
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias upload
```

Then create `android/key.properties`:

```properties
storePassword=<keystore password>
keyPassword=<key password>
keyAlias=upload
storeFile=/home/<you>/upload-keystore.jks
```

## Fonts

`assets/fonts/PlayfairDisplay.ttf` is subset to Latin-1 and common
punctuation, keeping its weight axis and all OpenType features (it needs
`lnum` for lining figures). To add characters, re-subset the original from
Google Fonts with fontTools:

```sh
pyftsubset PlayfairDisplay[wght].ttf --output-file=assets/fonts/PlayfairDisplay.ttf \
  --unicodes=U+0020-007E,U+00A0-00FF,U+0131,U+0152-0153,U+02C6,U+02DA,U+02DC,U+2013-2014,U+2018-201A,U+201C-201E,U+2020-2022,U+2026,U+2030,U+2039-203A,U+20AC,U+20B9,U+2122 \
  --layout-features='*'
```

Noto Serif Bengali is left whole. A subset with only the letters the app uses
renders slightly differently on Android, because FreeType's auto-hinter
measures reference letters (such as ক) that such a subset drops.

## Layout

```
lib/
  main.dart, app.dart   entry point, MaterialApp and shared state
  theme/                colours, typography, Material 3 theme, image paths
                        (AppImages), motion tokens (AppMotion)
  models/               Pandal, coordinate validation
  data/                 repository for pandals.json, map configuration
  services/             external maps links, device location, notifications,
                        settings saved on the device (AppStorage)
  state/                favourites, search/filter, nearby alerts, AppScope
  widgets/              reusable UI, cards, headers; map/ pins, overlays,
                        previews; motion/ animation building blocks
  screens/              Splash, Home, Pandal list, Map, Favourites, Pandal details
tool/                   developer-only verification tool (not part of the app)
assets/data/            pandals.json (bundled); backups/ written by the tool
assets/images/          images cropped from the approved redesign
assets/reference/       source poster (not bundled into the app)
assets/fonts/           Playfair Display, Noto Serif Bengali (SIL Open Font License)
design/                 approved redesign mockup and app screenshots (not bundled)
```

Pandal photos can later be bundled under `assets/images/` and referenced via
`Pandal.imageAsset`; until then a representative image is shown.
