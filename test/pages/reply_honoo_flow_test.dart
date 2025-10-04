import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:honoo/Pages/ReplyHonooPage.dart';
import 'package:honoo/Entities/Honoo.dart';

void main() {
  testWidgets('ReplyHonooPage: si costruisce, accetta input e mostra azione di invio',
          (tester) async {
        // Crea l'Honoo originale con il COSTRUTTORE POSIZIONALE (7 argomenti obbligatori)
        final original = Honoo(
          1,                                // id
          '“Testo origine”',                // text
          '',                               // image_url
          '2024-01-01T00:00:00Z',           // created_at
          '2024-01-01T00:00:00Z',           // updated_at
          'user_1',                         // user_id
          HonooType.personal,               // type
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ReplyHonooPage(
              originalHonoo: original,      // <-- richiesto dalla tua pagina
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Deve esserci un campo di testo per la risposta
        final tf = find.byType(TextField).first;
        expect(tf, findsOneWidget);

        // Inserisci una risposta
        await tester.enterText(tf, '“risposta di prova”');
        await tester.pump();

        // Trova un pulsante per inviare (adatta se hai un label diverso)
        final sendButton = find.textContaining('Invia', findRichText: true);
        expect(sendButton, findsWidgets); // almeno uno presente

        // Tap senza aspettarsi chiamate di rete (evitiamo mock di statici)
        await tester.tap(sendButton.first);
        await tester.pump(); // nessun crash
      });
}
