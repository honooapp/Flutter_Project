import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Pages/placeholder_page.dart';
import 'package:honoo/Pages/storiestorie_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('la landing mostra Storiestorie e apre la pagina dedicata', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: PlaceholderPage()));
    await tester.pumpAndSettle();

    final libri = find.text('Libri');
    expect(libri, findsOneWidget);
    final storiestorie = find.text('Storiestorie.it');
    expect(storiestorie, findsOneWidget);
    expect(find.byKey(const Key('storiestorie_icon')), findsOneWidget);

    await tester.ensureVisible(storiestorie);
    await tester.tap(storiestorie);
    await tester.pumpAndSettle();

    expect(find.byType(StoriestoriePage), findsOneWidget);
  });

  testWidgets('la pagina mostra il testo e il collegamento al sito', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: StoriestoriePage()));
    await tester.pumpAndSettle();

    final text = tester.widget<Text>(find.byKey(const Key('section_text')));
    expect(text.textSpan?.toPlainText(), StoriestoriePage.pageText);
    expect(text.textAlign, TextAlign.center);
    expect(StoriestoriePage.siteUri, Uri.parse('https://www.storiestorie.it'));

    final rootSpan = text.textSpan! as TextSpan;
    final linkSpan = rootSpan.children!.whereType<TextSpan>().first;
    expect(linkSpan.text, 'storiestorie.it\n\n');
    expect(linkSpan.style?.fontWeight, FontWeight.w700);
    expect(linkSpan.style?.decoration, TextDecoration.underline);
    expect(linkSpan.recognizer, isA<TapGestureRecognizer>());
  });
}
