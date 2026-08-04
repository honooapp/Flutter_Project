import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Pages/new_hinoo_page.dart';
import 'package:honoo/Pages/new_honoo_page.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Widgets/composer_onboarding.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpOnboarding(
    WidgetTester tester, {
    required Size size,
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size, textScaler: textScaler),
          child: const ComposerOnboardingPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mostra solo i due blocchi di composizione', (tester) async {
    await pumpOnboarding(tester, size: const Size(390, 844));

    expect(find.text('Scegli'), findsNWidgets(2));
    expect(find.text('per comporre il tuo honoo'), findsOneWidget);
    expect(find.text('per comporre il tuo hinoo'), findsOneWidget);
    expect(find.text('Se clicchi'), findsNothing);
    expect(find.text('non vedrai più questa schermata.'), findsNothing);
    expect(find.byKey(const Key('composer_onboarding_bottle')), findsOneWidget);
    expect(
      find.byKey(const Key('composer_onboarding_feather')),
      findsOneWidget,
    );
    expect(find.byTooltip('Componi il tuo honoo'), findsNothing);
    expect(find.byTooltip('Componi il tuo hinoo'), findsNothing);
  });

  testWidgets('la bottiglia apre il format honoo', (tester) async {
    await pumpOnboarding(tester, size: const Size(390, 844));

    await tester.tap(find.byKey(const Key('composer_onboarding_bottle')));
    await tester.pumpAndSettle();

    expect(find.byType(NewHonooPage), findsOneWidget);
  });

  testWidgets('la piuma apre il format hinoo', (tester) async {
    await pumpOnboarding(tester, size: const Size(390, 844));

    final feather = find.byKey(const Key('composer_onboarding_feather'));
    final icon = tester.widget<SvgPicture>(
      find.descendant(of: feather, matching: find.byType(SvgPicture)),
    );
    expect(
      (icon.bytesLoader as SvgAssetLoader).assetName,
      'assets/icons/testo.svg',
    );
    expect(
      icon.colorFilter,
      const ColorFilter.mode(HonooColor.onBackground, BlendMode.srcIn),
    );

    await tester.tap(feather);
    await tester.pumpAndSettle();

    expect(find.byType(NewHinooPage), findsOneWidget);
  });

  testWidgets('testo e icone delle azioni restano sulla stessa riga', (
    tester,
  ) async {
    await pumpOnboarding(tester, size: const Size(320, 568));

    final actionText = find.text('Scegli');
    expect(actionText, findsNWidgets(2));

    expect(
      tester.getCenter(actionText.at(0)).dy,
      closeTo(
        tester
            .getCenter(find.byKey(const Key('composer_onboarding_bottle')))
            .dy,
        1,
      ),
    );
    expect(
      tester.getCenter(actionText.at(1)).dy,
      closeTo(
        tester
            .getCenter(find.byKey(const Key('composer_onboarding_feather')))
            .dy,
        1,
      ),
    );
  });

  testWidgets('le icone crescono proporzionalmente al testo', (tester) async {
    await pumpOnboarding(tester, size: const Size(390, 844));
    final bottle = find.descendant(
      of: find.byKey(const Key('composer_onboarding_bottle')),
      matching: find.byType(SvgPicture),
    );
    final baseWidth = tester.getSize(bottle).width;

    await pumpOnboarding(
      tester,
      size: const Size(390, 844),
      textScaler: const TextScaler.linear(1.5),
    );

    expect(tester.getSize(bottle).width, closeTo(baseWidth * 1.5, 0.1));
  });

  testWidgets('il selettore entra nel viewport mobile senza scroll', (
    tester,
  ) async {
    await pumpOnboarding(tester, size: const Size(390, 844));

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.maxScrollExtent, 0);
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
