import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Pages/home_page.dart';
import 'package:mocktail/mocktail.dart';

import '../test_supabase_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseTestHarness harness;

  setUpAll(registerSupabaseFallbacks);

  setUp(() {
    harness = SupabaseTestHarness();
    harness.enableOverrides();
    final visit = MockQueryChain();
    when(
      () => harness.client.rpc('increment_site_visit'),
    ).thenAnswer((_) => visit);
  });

  tearDown(() {
    harness.disableOverrides();
  });

  Future<void> pumpHomeAtSize(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pump();
  }

  testWidgets('solleva solo il testo introduttivo in modo responsive', (
    tester,
  ) async {
    await pumpHomeAtSize(tester, const Size(320, 500));

    Transform intro = tester.widget(find.byKey(const Key('home_intro_lift')));
    expect(intro.transform.getTranslation().y, -6);

    await pumpHomeAtSize(tester, const Size(1440, 1000));

    intro = tester.widget(find.byKey(const Key('home_intro_lift')));
    expect(intro.transform.getTranslation().y, -10);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
