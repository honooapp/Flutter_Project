import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Pages/placeholder_page.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Widgets/smooth_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.platformDispatcher.clearAllTestValues();
  });

  Future<void> pumpLanding(WidgetTester tester, {required Size size}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;

    await tester.pumpWidget(const MaterialApp(home: PlaceholderPage()));
    await tester.pumpAndSettle();
  }

  testWidgets('dopo il bootstrap la landing mobile ha sfondo blu pieno', (
    tester,
  ) async {
    await pumpLanding(tester, size: const Size(390, 844));

    final scaffold = tester.widget<Scaffold>(
      find.byKey(const Key('public_landing_screen_root')),
    );

    expect(scaffold.backgroundColor, HonooColor.background);
    expect(find.byType(SmoothImage), findsNothing);

    final luna = tester.widget<Image>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == 'assets/icons/luna.png',
      ),
    );
    final feste = tester.widget<Image>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == 'assets/icons/feste.png',
      ),
    );
    expect(luna.height, 75);
    final lunaTransform = tester.widget<Transform>(
      find.byKey(const Key('luna_icon_transform')),
    );
    expect(lunaTransform.transform.getTranslation().y, -2);
    expect(feste.height, 66);
  });

  testWidgets('tablet e desktop mantengono il background attuale', (
    tester,
  ) async {
    await pumpLanding(tester, size: const Size(1024, 768));

    final smoothImage = tester.widget<SmoothImage>(find.byType(SmoothImage));
    expect(
      (smoothImage.image as AssetImage).assetName,
      'assets/background.webp',
    );
  });
}
