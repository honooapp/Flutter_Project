import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Pages/placeholder_page.dart';
import 'package:honoo/Pages/storiestorie_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('la landing apre Storiestorie dopo Libri', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: PlaceholderPage()));
    await tester.pumpAndSettle();

    final libri = find.text('Libri');
    final link = find.text('Storiestorie.it');
    expect(libri, findsOneWidget);
    expect(link, findsOneWidget);
    expect(find.byKey(const Key('storiestorie_icon')), findsOneWidget);

    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .whereType<String>()
        .toList();
    expect(texts.indexOf('Storiestorie.it'), texts.indexOf('Libri') + 1);

    await tester.ensureVisible(link);
    await tester.tap(link);
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
