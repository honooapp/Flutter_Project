import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Pages/new_hinoo_page.dart';
import 'package:honoo/Pages/new_honoo_page.dart';
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

    await tester.pumpWidget(const MaterialApp(home: ComposerOnboardingPage()));
    await tester.pumpAndSettle();
  }

  testWidgets('mostra solo i due blocchi di composizione', (tester) async {
    await pumpOnboarding(tester, size: const Size(390, 844));

    expect(find.text('Clicca qui'), findsNWidgets(2));
    expect(find.text('per comporre il tuo honoo'), findsOneWidget);
    expect(find.text('per comporre il tuo hinoo'), findsOneWidget);
    expect(find.text('Se clicchi'), findsNothing);
    expect(find.text('non vedrai più questa schermata.'), findsNothing);
    expect(find.byKey(const Key('composer_onboarding_bottle')), findsOneWidget);
    expect(
      find.byKey(const Key('composer_onboarding_feather')),
      findsOneWidget,
    );
  });

  testWidgets('la bottiglia apre il format honoo', (tester) async {
    await pumpOnboarding(tester, size: const Size(390, 844));

    await tester.tap(find.byKey(const Key('composer_onboarding_bottle')));
    await tester.pumpAndSettle();

    expect(find.byType(NewHonooPage), findsOneWidget);
  });

  testWidgets('la piuma apre il format hinoo', (tester) async {
    await pumpOnboarding(tester, size: const Size(390, 844));

    await tester.tap(find.byKey(const Key('composer_onboarding_feather')));
    await tester.pumpAndSettle();

    expect(find.byType(NewHinooPage), findsOneWidget);
  });

  testWidgets('la X chiude il selettore senza nasconderlo in futuro', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'composer_onboarding_dismissed_v1': true,
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            key: const Key('open_composer'),
            onPressed: () => ComposerLauncher.open(context),
            child: const Text('Apri'),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open_composer')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('composer_onboarding_page')), findsOneWidget);

    await tester.tap(find.byKey(const Key('composer_onboarding_close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('open_composer')), findsOneWidget);

    await tester.tap(find.byKey(const Key('open_composer')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('composer_onboarding_page')), findsOneWidget);
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
