import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Services/composer_onboarding_service.dart';
import 'package:honoo/Widgets/composer_onboarding.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpOnboarding(WidgetTester tester, {required Size size}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: ComposerOnboardingPage(
          service: ComposerOnboardingService(isSuppressed: () => false),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mostra tutti gli elementi e salva la chiusura', (tester) async {
    await pumpOnboarding(tester, size: const Size(390, 844));

    expect(find.text('Clicca qui'), findsNWidgets(2));
    expect(find.text('per comporre il tuo honoo'), findsOneWidget);
    expect(find.text('per comporre il tuo hinoo'), findsOneWidget);
    expect(find.text('non vedrai più questa schermata.'), findsOneWidget);
    expect(find.byKey(const Key('composer_onboarding_bottle')), findsOneWidget);
    expect(
      find.byKey(const Key('composer_onboarding_feather')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('composer_onboarding_close')));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool(ComposerOnboardingService.preferenceKey),
      isTrue,
    );
  });

  for (final size in <Size>[
    const Size(320, 568),
    const Size(390, 844),
    const Size(768, 1024),
    const Size(1440, 900),
  ]) {
    testWidgets('non va in overflow a ${size.width}x${size.height}', (
      tester,
    ) async {
      await pumpOnboarding(tester, size: size);

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const Key('composer_onboarding_scroll')),
        findsOneWidget,
      );
    });
  }
}
