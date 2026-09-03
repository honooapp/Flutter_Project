import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/IsolaDelleStorie/Pages/campanelli_page.dart';
import 'package:honoo/Pages/bando_honoo_francolise_page.dart';
import 'package:honoo/Pages/feste_page.dart';
import 'package:honoo/Pages/la_banda_page.dart';
import 'package:honoo/Pages/laboratori_siae_page.dart';
import 'package:honoo/Pages/libri_page.dart';
import 'package:honoo/Pages/luna_page.dart';
import 'package:honoo/Pages/performance_page.dart';
import 'package:honoo/Pages/podcast_dirette_page.dart';
import 'package:honoo/Pages/regia_agenti_page.dart';
import 'package:honoo/Pages/storiestorie_page.dart';
import 'package:honoo/Pages/viaggi_isola_page.dart';
import 'package:mocktail/mocktail.dart';

import '../test_supabase_helper.dart';

Iterable<TextSpan> _allTextSpans(InlineSpan span) sync* {
  if (span is! TextSpan) return;

  yield span;
  for (final child in span.children ?? const <InlineSpan>[]) {
    yield* _allTextSpans(child);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  registerSupabaseFallbacks();

  final sections = <(String, Widget)>[
    ('Performance', const PerformancePage()),
    ('Laboratori teatrali', const LaboratoriSiaePage()),
    ('Esplorazioni lunari', const LunaPage()),
    ('Feste', const FestePage()),
    ("Viaggi sull'Isola delle Storie", const ViaggiIsolaPage()),
    ('La Banda', const LaBandaPage()),
    ('Bando honoo per Dugenta', const BandoHonooFrancolisePage()),
    ('Regia degli Agenti', const RegiaAgentiPage()),
    ('Podcast e dirette', const PodcastDirettePage()),
    ('Libri', const LibriPage()),
    ('storiestorie.it', const StoriestoriePage()),
  ];

  for (final (title, page) in sections) {
    testWidgets(
      '$title ha il titolo iniziale in grassetto e due a capo finali',
      (tester) async {
        await tester.pumpWidget(MaterialApp(home: page));
        await tester.pumpAndSettle();

        final contentFinder = find.byKey(const Key('section_text'));
        expect(contentFinder, findsOneWidget);

        final Widget content = tester.widget(contentFinder);
        final String plainText;
        if (content is Text) {
          plainText = content.data ?? content.textSpan!.toPlainText();
        } else if (content is RichText) {
          plainText = content.text.toPlainText();
        } else {
          final textWidgets = tester.widgetList<Text>(
            find.descendant(of: contentFinder, matching: find.byType(Text)),
          );
          plainText = textWidgets
              .map((text) => text.data ?? text.textSpan!.toPlainText())
              .join();
        }

        expect(plainText, startsWith('$title\n\n'));
        if (page is ViaggiIsolaPage) {
          expect(plainText, endsWith('\n\n\n\n'));
        } else {
          expect(plainText, endsWith('\n\n'));
          expect(plainText, isNot(endsWith('\n\n\n')));
        }

        final titleSpan = tester
            .widgetList<RichText>(find.byType(RichText))
            .expand((richText) => _allTextSpans(richText.text))
            .firstWhere((span) => span.text?.startsWith('$title\n\n') ?? false);
        expect(titleSpan.style?.fontWeight, FontWeight.w700);
      },
    );
  }

  testWidgets(
    'Viaggi Isola mostra il collegamento in grassetto verso i Campanelli',
    (tester) async {
      final harness = SupabaseTestHarness()..enableOverrides();
      addTearDown(harness.disableOverrides);
      final publicCampanelliQuery = MockQueryChain()
        ..queueResponse(<dynamic>[]);
      when(
        () => harness.client.rpc('get_public_admin_campanelli'),
      ).thenAnswer((_) => publicCampanelliQuery);

      await tester.pumpWidget(const MaterialApp(home: ViaggiIsolaPage()));
      await tester.pumpAndSettle();

      final linkFinder = find.byKey(const Key('campanelli_link'));
      expect(linkFinder, findsOneWidget);
      expect(find.textContaining('i leoni,'), findsNothing);
      expect(find.textContaining('ma questo'), findsNothing);
      expect(find.textContaining('Vuoi scoprire\nche c’è?'), findsOneWidget);

      final linkText = tester.widget<Text>(
        find.descendant(of: linkFinder, matching: find.byType(Text)),
      );
      expect(linkText.data, 'Vieni a vedere\n\n\n\n');
      expect(linkText.style?.fontWeight, FontWeight.w700);
      expect(linkText.style?.decoration, TextDecoration.underline);
      expect(linkText.style?.decorationColor, linkText.style?.color);
      expect(linkText.style?.decorationThickness, 3);

      await tester.ensureVisible(linkFinder);
      await tester.tap(linkFinder);
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      expect(find.byType(CampanelliPage), findsOneWidget);
    },
  );
}
