import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Pages/la_banda_page.dart';
import 'package:honoo/Pages/placeholder_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('la landing apre La Banda dal link e dalla sua icona', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: PlaceholderPage()));
    await tester.pumpAndSettle();

    final link = find.text('La Banda');
    final icon = find.byIcon(Icons.groups);
    expect(link, findsOneWidget);
    expect(icon, findsOneWidget);

    await tester.ensureVisible(link);
    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(find.byType(LaBandaPage), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await tester.ensureVisible(icon);
    await tester.tap(icon);
    await tester.pumpAndSettle();
    expect(find.byType(LaBandaPage), findsOneWidget);
  });

  testWidgets('La Banda mostra il testo completo nello stile informativo', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LaBandaPage()));
    await tester.pumpAndSettle();

    final section = find.byKey(const Key('section_text'));
    final text = tester.widget<Text>(
      find.descendant(of: section, matching: find.byType(Text)),
    );
    expect(text.textSpan?.toPlainText(), LaBandaPage.laBandaText);
    expect(text.textAlign, TextAlign.center);
    expect(text.textSpan?.style?.fontSize, 18);
    expect(text.textSpan?.style?.height, 1.3);
    expect(
      text.textSpan?.toPlainText(),
      startsWith('La Banda\n\nImmagina un gruppo'),
    );
    expect(
      text.textSpan?.toPlainText(),
      contains('Prima regola:\nparlano tutti,\na turno'),
    );
    expect(
      text.textSpan?.toPlainText(),
      endsWith('che queste tre regole\nvengano rispettate\n\n'),
    );
  });
}
