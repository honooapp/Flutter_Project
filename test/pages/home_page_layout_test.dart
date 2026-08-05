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

  testWidgets('mostra il nuovo testo e le azioni inline senza scroll', (
    tester,
  ) async {
    await pumpHomeAtSize(tester, const Size(320, 500));

    final intro = find.byKey(const Key('home_intro_text'));
    expect(intro, findsOneWidget);
    expect(find.textContaining('Ti regaliamo la Luna'), findsOneWidget);
    expect(find.textContaining('verso le tue storie'), findsOneWidget);
    expect(find.byType(Scrollable), findsNothing);
    expect(find.byKey(const Key('home_inline_bottle')), findsOneWidget);
    expect(find.byKey(const Key('home_inline_moon')), findsOneWidget);
    expect(find.byKey(const Key('home_inline_island')), findsOneWidget);
    expect(find.byKey(const Key('home_bottle_leading_gap')), findsOneWidget);
    expect(find.byKey(const Key('home_moon_leading_gap')), findsOneWidget);
    expect(find.byKey(const Key('home_island_leading_gap')), findsOneWidget);

    for (final key in const [
      Key('home_bottle_leading_gap'),
      Key('home_moon_leading_gap'),
      Key('home_island_leading_gap'),
    ]) {
      expect(tester.getSize(find.byKey(key)).width, 8);
    }

    for (final entry in const [
      (Key('home_inline_bottle'), 42.0),
      (Key('home_inline_moon'), 28.0),
      (Key('home_inline_island'), 43.0),
    ]) {
      final key = entry.$1;
      final button = tester.widget<IconButton>(find.byKey(key));
      expect(button.onPressed, isNotNull);
      expect(button.constraints!.maxWidth, entry.$2);
      expect(button.constraints!.maxHeight, entry.$2);
    }

    await pumpHomeAtSize(tester, const Size(1440, 1000));

    expect(find.byKey(const Key('home_intro_text')), findsOneWidget);
    expect(find.byType(Scrollable), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
