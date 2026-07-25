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

  testWidgets('Luna e Scrigno riapplicano il ritaglio salvato dello sfondo',
      (tester) async {
    const transform = <double>[
      1.4, 0, 0, 0,
      0, 1.4, 0, 0,
      0, 0, 1.4, 0,
      120, -90, 0, 1,
    ];
    const slide = HinooSlide(
      backgroundImage: null,
      text: 'Inquadratura invariata',
      isTextWhite: true,
      bgTransform: transform,
    );
    final roundTrip = HinooSlide.fromJson(slide.toJson());

    await tester.pumpWidget(
      MaterialApp(
        home: HinooSlideView(
          slide: roundTrip,
          width: 360,
          height: 640,
          gap: 0,
          gapColor: Colors.black,
        ),
      ),
    );
    await tester.pump();

    expect(roundTrip.bgTransform, transform);
    final backgroundTransform = tester.widget<Transform>(
      find.byKey(const ValueKey('hinoo-saved-background-transform')),
    );
    expect(backgroundTransform.transform.storage[0], closeTo(1.4, 0.001));
    expect(backgroundTransform.transform.storage[5], closeTo(1.4, 0.001));
    expect(backgroundTransform.transform.storage[12], closeTo(40, 0.001));
    expect(backgroundTransform.transform.storage[13], closeTo(-30, 0.001));
  });
}
