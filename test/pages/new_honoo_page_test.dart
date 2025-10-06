// test/pages/new_honoo_page_smoke_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Pages/NewHonooPage.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('NewHonooPage si costruisce e accetta input di testo',
      (tester) async {
    await pumpSizerApp(tester, const NewHonooPage());

    final tf = find.byType(TextField).first;
    expect(tf, findsOneWidget);

    await tester.enterText(tf, '“Ciao luna”');
    await tester.pump();

    // bottone di salvataggio presente (icona OK con tooltip)
    final saveButton = find.byTooltip('Salva honoo');
    expect(saveButton, findsOneWidget);
  });
}
