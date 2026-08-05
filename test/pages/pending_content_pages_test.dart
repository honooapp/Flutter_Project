import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Entities/hinoo.dart';
import 'package:honoo/Entities/honoo.dart';
import 'package:honoo/IsolaDelleStorie/Pages/pending_hinoo_page.dart';
import 'package:honoo/IsolaDelleStorie/Pages/pending_honoo_page.dart';
import 'package:honoo/Utility/honoo_colors.dart';

import '../test_supabase_helper.dart';

void main() {
  setUpAll(registerSupabaseFallbacks);

  late SupabaseTestHarness harness;

  setUp(() {
    harness = SupabaseTestHarness(withAuthenticatedUser: true)
      ..enableOverrides();
  });

  tearDown(() {
    harness.disableOverrides();
  });

  Future<void> pumpRoute(
    WidgetTester tester, {
    required Widget page,
    required ValueChanged<bool?> onResult,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              onResult(
                await Navigator.of(
                  context,
                ).push<bool>(MaterialPageRoute(builder: (_) => page)),
              );
            },
            child: const Text('Apri anteprima'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Apri anteprima'));
    await tester.pumpAndSettle();
  }

  testWidgets('PendingHinooPage restituisce true con Apri', (tester) async {
    bool? result;
    const draft = HinooDraft(
      pages: [
        HinooSlide(
          backgroundImage: null,
          text: 'Hinoo in attesa',
          isTextWhite: true,
        ),
      ],
      type: HinooType.answer,
    );

    await pumpRoute(
      tester,
      page: const PendingHinooPage(draft: draft),
      onResult: (value) => result = value,
    );

    expect(find.byType(PendingHinooPage), findsOneWidget);
    expect(find.text('Hinoo in attesa'), findsOneWidget);
    final cancelIcon = tester.widget<SvgPicture>(
      find.descendant(
        of: find.byTooltip('Non ora'),
        matching: find.byType(SvgPicture),
      ),
    );
    expect(
      cancelIcon.colorFilter,
      const ColorFilter.mode(HonooColor.onBackground, BlendMode.srcIn),
    );
    await tester.tap(find.bySemanticsLabel('OK'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('PendingHonooPage restituisce false con Non ora', (tester) async {
    bool? result;
    final honoo = Honoo(
      1,
      'Honoo in attesa',
      '',
      '2026-07-18T12:00:00Z',
      '2026-07-18T12:00:00Z',
      'visitor-1',
      HonooType.answer,
    );

    await pumpRoute(
      tester,
      page: PendingHonooPage(honoo: honoo),
      onResult: (value) => result = value,
    );

    expect(find.byType(PendingHonooPage), findsOneWidget);
    expect(find.text('Honoo in attesa'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Annulla'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });
}
