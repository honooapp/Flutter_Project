import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Entities/honoo.dart';
import 'package:honoo/UI/honoo_card.dart';
import 'package:honoo/Utility/honoo_colors.dart';

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
    final honoo = Honoo(
      1,
      'Ciao Luna',
      '',
      '2026-01-01T00:00:00Z',
      '2026-01-01T00:00:00Z',
      'user-id',
      HonooType.moon,
    );

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
}
