import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/IsolaDelleStorie/Pages/campanelli_page.dart';
import 'package:honoo/Widgets/campanelli_footer.dart';
import 'package:honoo/Widgets/campanello_card.dart';
import 'package:honoo/Widgets/casa_section.dart';
import 'package:honoo/Widgets/desktop_carousel_arrows.dart';

import '../test_supabase_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseTestHarness harness;

  setUpAll(registerSupabaseFallbacks);

  setUp(() {
    harness = SupabaseTestHarness();
    harness.enableOverrides();
  });

  tearDown(() => harness.disableOverrides());

  Future<void> pumpAtSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: CampanelliPage()));
    await tester.pump();
  }

  testWidgets('Campanelli mantiene la struttura su viewport mobile', (
    tester,
  ) async {
    await pumpAtSize(tester, const Size(390, 844));

    expect(find.byType(CampanelloCard), findsOneWidget);
    expect(find.byType(CampanelliFooter), findsOneWidget);
    expect(find.byType(DesktopCarouselArrows), findsOneWidget);
    final CampanelloCard card = tester.widget(find.byType(CampanelloCard));
    expect(card.width, 390);
    expect(card.height, 844);
    expect(tester.takeException(), isNull);
  });

  testWidgets('le frecce del carosello si dissolvono dopo quattro secondi', (
    tester,
  ) async {
    await pumpAtSize(tester, const Size(390, 844));

    AnimatedOpacity arrows = tester.widget(
      find.byKey(const ValueKey<String>('campanelli_carousel_arrows')),
    );
    expect(arrows.opacity, 1);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 300));

    arrows = tester.widget(
      find.byKey(const ValueKey<String>('campanelli_carousel_arrows')),
    );
    expect(arrows.opacity, 0);
  });

  testWidgets('Campanelli mantiene la struttura su viewport desktop', (
    tester,
  ) async {
    await pumpAtSize(tester, const Size(1200, 900));

    expect(find.byType(CampanelloCard), findsOneWidget);
    expect(find.byType(CampanelliFooter), findsOneWidget);
    final CampanelloCard card = tester.widget(find.byType(CampanelloCard));
    expect(card.width, closeTo(506.25, 0.01));
    expect(card.height, 900);
    expect(tester.getSize(find.byType(CampanelliFooter)).width, 506.25);

    await tester.drag(find.byType(CampanelloCard), const Offset(0, -900));
    await tester.pumpAndSettle();

    final CasaSection casa = tester.widget(find.byType(CasaSection));
    expect(casa.width, closeTo(506.25, 0.01));
    expect(casa.height, 900);
    expect(tester.takeException(), isNull);
  });
}
