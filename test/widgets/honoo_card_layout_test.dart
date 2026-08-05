import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Entities/honoo.dart';
import 'package:honoo/Pages/moon_page.dart';
import 'package:honoo/UI/honoo_card.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Widgets/smooth_image.dart';

import '../test_supabase_helper.dart';

void main() {
  setUpAll(registerSupabaseFallbacks);

  late SupabaseTestHarness harness;

  setUp(() {
    harness = SupabaseTestHarness()..enableOverrides();
  });

  tearDown(() {
    harness.disableOverrides();
  });

  testWidgets('il separatore dell honoo Luna usa il bianco dello sfondo', (
    tester,
  ) async {
    final honoo = MoonPage.honooFromMoonRow({
      'id': 'moon-honoo-id',
      'text': 'Ciao Luna',
      'image_url': '',
      'created_at': '2026-01-01T00:00:00Z',
      'user_id': 'user-id',
      // moon_public non espone il campo destination.
    });

    expect(honoo.type, HonooType.moon);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 459,
              child: HonooCard(honoo: honoo),
            ),
          ),
        ),
      ),
    );

    final gap = tester.widget<ColoredBox>(
      find.byKey(const Key('honoo-card-gap')),
    );
    expect(gap.color, HonooColor.tertiary);
  });

  testWidgets(
    'Luna e Scrigno mostrano il ritaglio Honoo senza trasformazioni',
    (tester) async {
      final honoo = Honoo(
        1,
        'Ritaglio salvato',
        'https://example.com/saved-square.png',
        '2026-01-01T00:00:00Z',
        '2026-01-01T00:00:00Z',
        'user-id',
        HonooType.personal,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 459,
              child: HonooCard(honoo: honoo),
            ),
          ),
        ),
      );

      final image = tester.widget<SmoothImage>(
        find.byKey(const ValueKey('honoo-saved-image')),
      );
      expect(image.fit, BoxFit.cover);
      expect(image.alignment, Alignment.center);
      final renderedSize = tester.getSize(
        find.byKey(const ValueKey('honoo-saved-image')),
      );
      expect(renderedSize.width, closeTo(renderedSize.height, 0.01));
      expect(renderedSize.width, closeTo(300, 0.5));
    },
  );
}
