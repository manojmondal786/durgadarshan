import 'package:durga_darshan/app.dart';
import 'package:durga_darshan/data/app_links.dart';
import 'package:durga_darshan/services/app_storage.dart';
import 'package:durga_darshan/services/external_maps.dart';
import 'package:durga_darshan/services/install_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_location.dart';
import 'helpers/fake_tiles.dart';
import 'helpers/test_data.dart';

void main() {
  final realOpener = ExternalMaps.opener;
  late List<Uri> opened;

  setUp(() {
    opened = [];
    ExternalMaps.opener = (uri) async {
      opened.add(uri);
      return true;
    };
  });

  tearDown(() => ExternalMaps.opener = realOpener);

  Future<void> pumpApp(
    WidgetTester tester, {
    required InstallTarget? target,
    AppStorage? storage,
  }) async {
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      DurgaDarshanApp(
        repository: loadBundledPandals(),
        storage: storage ?? MemoryStorage(),
        mapTileProvider: FakeTileProvider(),
        locationSource: FakeLocationSource(),
        alertPresenter: FakeAlertPresenter(),
        detectInstall: () => target,
      ),
    );
    await tester.pumpAndSettle();
  }

  test('the installed apps never suggest installing', () {
    expect(detectInstallTarget(), isNull);
  });

  testWidgets('no banner unless in a phone browser', (tester) async {
    await pumpApp(tester, target: null);
    expect(find.text('Add the app to your Home Screen'), findsNothing);
    expect(find.text('Get the Android app'), findsNothing);
  });

  testWidgets('iPhone browsers are shown how to add it to the Home Screen', (
    tester,
  ) async {
    final storage = MemoryStorage();
    await pumpApp(
      tester,
      target: InstallTarget.iosHomeScreen,
      storage: storage,
    );

    expect(find.text('Add the app to your Home Screen'), findsOneWidget);
    expect(find.textContaining('Add to Home Screen'), findsOneWidget);
    expect(find.byIcon(Icons.ios_share_rounded), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Add the app to your Home Screen'), findsNothing);
    expect(storage.installHintDismissed, isTrue);

    // Stays closed on the next visit.
    await tester.pumpWidget(const SizedBox());
    await pumpApp(
      tester,
      target: InstallTarget.iosHomeScreen,
      storage: storage,
    );
    expect(find.text('Add the app to your Home Screen'), findsNothing);
  });

  testWidgets('Android browsers are offered the Android app', (tester) async {
    await pumpApp(tester, target: InstallTarget.androidApp);

    expect(find.text('Get the Android app'), findsOneWidget);
    await tester.tap(find.text('Download the app'));
    await tester.pumpAndSettle();
    expect(opened, [AppLinks.androidApk]);
  });
}
