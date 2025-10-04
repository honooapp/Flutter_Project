import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Pages/NewHonooPage.dart';

void main() {
  testWidgets('la virgoletta di chiusura ” resta visibile anche al limite', (tester) async {
    await tester.pumpWidget(MaterialApp(home: NewHonooPage()));
    await tester.pumpAndSettle();

    final tf = find.byType(TextField).first;
    expect(tf, findsOneWidget);

    const input = '“Questo è un testo molto lungo che arriva al limite”';
    await tester.enterText(tf, input);
    await tester.pump();

    final allTexts = tester.widgetList<Text>(find.byType(Text));
    final hasClosing = allTexts.any((w) => (w.data ?? '').contains('”'));
    expect(hasClosing, isTrue, reason: 'La ” deve restare renderizzata.');
  });
}
