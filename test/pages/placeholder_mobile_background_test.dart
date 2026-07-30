import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Pages/placeholder_page.dart';
import 'package:honoo/Widgets/smooth_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.platformDispatcher.clearAllTestValues();
  });

  Future<String> pumpLandingAndReadBackground(
    WidgetTester tester, {
    required Size size,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;

    await tester.pumpWidget(const MaterialApp(home: PlaceholderPage()));
    await tester.pumpAndSettle();

    final smoothImage = tester.widget<SmoothImage>(find.byType(SmoothImage));
    return (smoothImage.image as AssetImage).assetName;
  }

  testWidgets('alterna palombaro e sirena tra due caricamenti mobile', (
    tester,
  ) async {
    final firstBackground = await pumpLandingAndReadBackground(
      tester,
      size: const Size(390, 844),
    );
    expect(firstBackground, 'assets/background palombaro.webp');

    await tester.pumpWidget(const SizedBox.shrink());

    final secondBackground = await pumpLandingAndReadBackground(
      tester,
      size: const Size(390, 844),
    );
    expect(secondBackground, 'assets/background sirena.webp');
  });

  testWidgets('tablet e desktop mantengono il background attuale', (
    tester,
  ) async {
    final background = await pumpLandingAndReadBackground(
      tester,
      size: const Size(1024, 768),
    );

    expect(background, 'assets/background.webp');
  });
}
