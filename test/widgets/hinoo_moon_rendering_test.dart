import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Entities/hinoo.dart';
import 'package:honoo/UI/hinoo_viewer.dart';

import '../test_supabase_helper.dart';

void main() {
  setUpAll(registerSupabaseFallbacks);

  late SupabaseTestHarness harness;

  setUp(() {
    harness = SupabaseTestHarness(withAuthenticatedUser: true)
      ..enableOverrides();
  });

  tearDown(() => harness.disableOverrides());

  testWidgets('Hinoo sulla Luna usa lo stesso rendering dell Hinoo salvato',
      (tester) async {
    const slide = HinooSlide(
      backgroundImage: null,
      text: 'Testo identico',
      isTextWhite: true,
      bgScale: 1.2,
      bgOffsetX: 12,
      bgOffsetY: -8,
    );

    Future<HinooSlideView> render(HinooType type) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HinooViewer(
            draft: HinooDraft(pages: const [slide], type: type),
            maxHeight: 640,
            maxWidth: 360,
          ),
        ),
      );
      await tester.pump();
      return tester.widget<HinooSlideView>(find.byType(HinooSlideView));
    }

    final saved = await render(HinooType.personal);
    final moon = await render(HinooType.moon);

    expect(moon.slide, same(saved.slide));
    expect(moon.width, saved.width);
    expect(moon.height, saved.height);
    expect(moon.gap, saved.gap);
    expect(moon.gapColor, saved.gapColor);
    expect(moon.scaleLegacyTextToFit, saved.scaleLegacyTextToFit);
  });

  testWidgets(
      'un Hinoo appena salvato mantiene il layout editor senza restringimento',
      (tester) async {
    const slide = HinooSlide(
      backgroundImage: null,
      text: 'Prima riga\nSeconda riga',
      isTextWhite: true,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: HinooViewer(
          draft: HinooDraft(
            pages: [slide],
            baseCanvasHeight: 640,
          ),
          maxHeight: 640,
          maxWidth: 360,
        ),
      ),
    );
    await tester.pump();

    final renderedSlide =
        tester.widget<HinooSlideView>(find.byType(HinooSlideView));

    expect(renderedSlide.scaleLegacyTextToFit, isFalse);
    expect(find.byKey(const ValueKey('hinoo-legacy-fitted-text')),
        findsNothing);
  });
}
