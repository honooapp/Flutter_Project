import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/IsolaDelleStorie/Pages/campanelli_page.dart';
import 'package:honoo/Widgets/campanelli_footer.dart';
import 'package:honoo/Widgets/campanello_card.dart';

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
    await tester.pumpWidget(
      const MaterialApp(home: CampanelliPage()),
    );
    await tester.pump();
  }

  testWidgets('Campanelli mantiene la struttura su viewport mobile',
      (tester) async {
    await pumpAtSize(tester, const Size(390, 844));

    expect(find.byType(CampanelloCard), findsOneWidget);
    expect(find.byType(CampanelliFooter), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Campanelli mantiene la struttura su viewport desktop',
      (tester) async {
    await pumpAtSize(tester, const Size(1200, 900));

    expect(find.byType(CampanelloCard), findsOneWidget);
    expect(find.byType(CampanelliFooter), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
