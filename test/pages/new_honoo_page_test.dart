// test/pages/new_honoo_page_smoke_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Pages/NewHonooPage.dart';

void main() {
  testWidgets('NewHonooPage si costruisce e accetta input di testo',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NewHonooPage()));
    await tester.pumpAndSettle();

    final tf = find.byType(TextField).first;
    expect(tf, findsOneWidget);

    await tester.enterText(tf, '“Ciao luna”');
    await tester.pump();

    // bottone di pubblicazione presente (adatta label se diverso)
    final publish = find.textContaining('Pubblica', findRichText: true);
    expect(publish, findsWidgets);
  });
}
