import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Pages/bando_honoo_francolise_page.dart';
import 'package:honoo/Pages/placeholder_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'la landing apre il Bando Francolise dal link e dalla sua icona',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: PlaceholderPage()));
      await tester.pumpAndSettle();

      final link = find.text('Bando honoo\nper Francolise');
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
    },
  );

  testWidgets('il Bando Francolise mostra il testo completo nello stile app', (
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
      startsWith('Bando honoo\nper Francolise\n\n'),
    );
    expect(text.textSpan?.toPlainText(), contains('del 31 agosto 2026'));
    expect(
      text.textSpan?.toPlainText(),
      contains('Behavior-Driven Development'),
    );
    expect(text.textSpan?.toPlainText(), contains('che ho citato'));
    expect(text.textSpan?.toPlainText(), isNot(contains('&#x20;')));
  });
}
