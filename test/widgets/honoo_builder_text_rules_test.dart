import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// importa il widget reale che vuoi testare
// es.: import 'package:honoo/UI/HonooBuilder.dart';
// oppure l'entry che costruisce il testo con la virgoletta
// ADATTA la riga qui sotto al tuo widget reale:

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('la virgoletta di chiusura ” resta visibile anche al limite', (tester) async {
    // 1) Monta il widget sotto test in un MaterialApp/Scaffold
    // SOSTITUISCI "WidgetUnderTest" con il tuo widget reale che mostra il testo con le virgolette.
    // Esempio 1: se hai un builder dedicato
    // final widget = WidgetUnderTest(text: '“ciao”');
    //
    // Esempio 2: semplice Text per riprodurre la regola
    final widget = const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('“ciao”')), // ADATTA qui al tuo caso reale
      ),
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    // 2) Trova la virgoletta di chiusura "”" anche se è in RichText
    // Prima prova con Text puro
    Finder quoteFinder = find.textContaining('”');

    // Se non trovi nulla, cerca anche nei RichText (textSpan.toPlainText)
    if (quoteFinder.evaluate().isEmpty) {
      quoteFinder = find.byWidgetPredicate((w) {
        if (w is RichText) {
          return w.text.toPlainText().contains('”');
        }
        return false;
      });
    }

    // 3) Verifica che almeno un widget contenga la virgoletta
    expect(
      quoteFinder,
      findsWidgets,
      reason:
      'Non è stato trovato alcun Text/RichText che contenga la virgoletta di chiusura ”',
    );

    // 4) (Opzionale) controlla che sia davvero visibile (non offstage)
    for (final e in quoteFinder.evaluate()) {
      expect(
        tester.any(find.byWidget(e.widget)),
        isTrue,
        reason: 'Il widget con la virgoletta ” non è montato correttamente',
      );
    }
  });
}
