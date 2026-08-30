import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Pages/bando_honoo_francolise_page.dart';
import 'package:honoo/Pages/placeholder_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('la landing apre il Bando Dugenta dal link e dalla sua icona', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: PlaceholderPage()));
    await tester.pumpAndSettle();

    final link = find.text('Bando honoo\nper Dugenta');
    final icon = find.byIcon(Icons.castle);
    expect(link, findsOneWidget);
    expect(icon, findsOneWidget);

    await tester.ensureVisible(link);
    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(find.byType(BandoHonooFrancolisePage), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await tester.ensureVisible(icon);
    await tester.tap(icon);
    await tester.pumpAndSettle();
    expect(find.byType(BandoHonooFrancolisePage), findsOneWidget);
  });

  testWidgets('il Bando Dugenta conserva anche l’archivio Francolise', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: BandoHonooFrancolisePage()),
    );
    await tester.pumpAndSettle();

    final section = find.byKey(const Key('section_text'));
    final text = tester.widget<Text>(
      find.descendant(of: section, matching: find.byType(Text)),
    );
    expect(text.textSpan?.toPlainText(), BandoHonooFrancolisePage.bandoText);
    expect(text.textAlign, TextAlign.center);
    expect(text.textSpan?.style?.fontSize, 18);
    expect(text.textSpan?.style?.height, 1.3);
    expect(
      text.textSpan?.toPlainText(),
      startsWith('Bando honoo per Dugenta\n\nSì, hai letto bene\n\n'),
    );
    expect(
      text.textSpan?.toPlainText(),
      contains('“per Dugenta”,\nin provincia di Benevento'),
    );
    expect(
      text.textSpan?.toPlainText(),
      contains('Dugenta Settanta: 1956 — 2026 — 2076'),
    );
    expect(
      text.textSpan?.toPlainText(),
      contains('come archivio\n\nBando honoo\nper Francolise\n\nHo proposto'),
    );
    final dugentaText = text.textSpan!
        .toPlainText()
        .split('\n\nBando honoo\nper Francolise')
        .first;
    expect(dugentaText, isNot(contains('\n\n\n')));
    expect(dugentaText, contains('attraverso nomi,\nvisi\npensieri.'));
    expect(dugentaText, contains('1° dicembre 1956, n. 1398'));
    expect(dugentaText, contains('il nome dell’eventuale antenato'));
    expect(dugentaText, contains('a ciò che l’abitante'));
    expect(
      dugentaText,
      contains('che cosa vorrebbe\nper Dugenta\ntra settant’anni,'),
    );
    expect(
      dugentaText,
      contains('ciascun cittadino\na realizzare\nquesta composizione poetica'),
    );
    final spans = (text.textSpan! as TextSpan).children!.cast<TextSpan>();
    final boldPassages = spans
        .where((span) => span.style?.fontWeight == FontWeight.w700)
        .map((span) => span.text)
        .toList();
    expect(boldPassages, [
      'Bando honoo per Dugenta\n\n',
      'il passato,\nil presente\ne il futuro',
      'nomi,\nvisi\npensieri.',
      'I nomi:',
      'performance',
      'I visi:',
      'installazione',
      'Passaporto',
      'Dugenta 70',
      'Dugenta 70',
      'I pensieri:',
      'Apri gli occhi:\nc’è Dugenta davanti a te',
      '2076. Apri gli occhi:\nc’è Dugenta davanti a te',
      'Dugenta Settanta: 1956 — 2026 — 2076',
    ]);
    expect(spans.last.style, isNull);
    expect(spans.last.text, contains('Bando honoo\nper Francolise'));
    expect(
      dugentaText,
      contains('Te lo racconto,\nma prima\nun ringraziamento'),
    );
    expect(text.textSpan?.toPlainText(), contains('del 31 agosto 2026'));
    expect(
      text.textSpan?.toPlainText(),
      contains('Behavior-Driven Development'),
    );
    expect(text.textSpan?.toPlainText(), contains('che ho citato'));
    expect(
      'Nei prossimi giorni'.allMatches(text.textSpan!.toPlainText()).length,
      1,
    );
    expect(
      text.textSpan?.toPlainText(),
      contains('Questo è l’aggiornamento\ndi oggi\ndomenica 23 agosto'),
    );
    expect(text.textSpan?.toPlainText(), contains('Carolina Franco'));
    expect(text.textSpan?.toPlainText(), contains('Giovanni Vanacore'));
    expect(text.textSpan?.toPlainText(), contains('Massimiliano Corrente'));
    expect(
      text.textSpan?.toPlainText(),
      contains('Questo è l’aggiornamento\ndi oggi\nlunedì 24 agosto'),
    );
    expect(
      text.textSpan?.toPlainText(),
      contains('Questo è l’aggiornamento\ndi oggi\nmartedì 25 agosto'),
    );
    expect(
      text.textSpan?.toPlainText(),
      contains('Questo è l’aggiornamento\ndi oggi\ngiovedì 27 agosto 2026'),
    );
    expect(
      text.textSpan?.toPlainText(),
      contains('Luca Cacciapuoti,\nArsenyco\n\n\n\nQuesto è l’aggiornamento'),
    );
    expect(
      text.textSpan?.toPlainText(),
      contains('sulla piattaforma ministeriale'),
    );
    expect(
      text.textSpan?.toPlainText(),
      contains('durante le feste di honoo,\nnella Stanza del Grafico'),
    );
    expect(
      text.textSpan?.toPlainText(),
      endsWith('honoo ha bisogno di te\n\nviva honoo\nviva la Banda\n\n'),
    );
    expect(text.textSpan?.toPlainText(), isNot(contains('&#x20;')));
  });
}
