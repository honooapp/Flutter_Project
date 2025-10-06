import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:honoo/Entities/Honoo.dart';
import 'package:honoo/Pages/ReplyHonooPage.dart';

import '../test_helpers.dart';

void main() {
  testWidgets(
      'ReplyHonooPage: si costruisce, accetta input e mostra azione di invio',
      (tester) async {
    // Crea l'Honoo originale con il COSTRUTTORE POSIZIONALE (7 argomenti obbligatori)
    final original = Honoo(
      1, // id
      '“Testo origine”', // text
      '', // image_url
      '2024-01-01T00:00:00Z', // created_at
      '2024-01-01T00:00:00Z', // updated_at
      'user_1', // user_id
      HonooType.personal, // type
    );

    await pumpSizerApp(
      tester,
      ReplyHonooPage(
        originalHonoo: original, // <-- richiesto dalla tua pagina
      ),
    );

    // Deve esserci un campo di testo per la risposta
    final tf = find.byType(TextField).first;
    expect(tf, findsOneWidget);

    // Inserisci una risposta
    await tester.enterText(tf, '“risposta di prova”');
    await tester.pump();

    // Trova un pulsante per inviare
    final sendButton = find.widgetWithText(ElevatedButton, 'Invia risposta');
    expect(sendButton, findsOneWidget);

    final buttonWidget = tester.widget<ElevatedButton>(sendButton);
    expect(buttonWidget.onPressed, isNotNull);
  });
}
