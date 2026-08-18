import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Pages/feste_page.dart';
import 'package:honoo/Pages/la_banda_page.dart';
import 'package:honoo/Pages/laboratori_siae_page.dart';
import 'package:honoo/Pages/libri_page.dart';
import 'package:honoo/Pages/luna_page.dart';
import 'package:honoo/Pages/performance_page.dart';
import 'package:honoo/Pages/podcast_dirette_page.dart';
import 'package:honoo/Pages/regia_agenti_page.dart';
import 'package:honoo/Pages/viaggi_isola_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sections = <(String, Widget)>[
    ('Performance', const PerformancePage()),
    ('Laboratori teatrali', const LaboratoriSiaePage()),
    ('Esplorazioni lunari', const LunaPage()),
    ('Feste', const FestePage()),
    ("Viaggi sull'Isola delle Storie", const ViaggiIsolaPage()),
    ('La Banda', const LaBandaPage()),
    ('Regia degli Agenti', const RegiaAgentiPage()),
    ('Podcast e dirette', const PodcastDirettePage()),
    ('Libri', const LibriPage()),
  ];

  for (final (title, page) in sections) {
    testWidgets('$title inizia col titolo del link e termina con due a capo', (
      tester,
    ) async {
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
      expect(plainText, endsWith('\n\n'));
      expect(plainText, isNot(endsWith('\n\n\n')));
    });
  }
}
