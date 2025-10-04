import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:honoo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('crea honoo e poi rispondi', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Naviga alla pagina di creazione (adatta il label del tuo bottone/menu)
    if (find.text('Nuovo Honoo').evaluate().isNotEmpty) {
      await tester.tap(find.text('Nuovo Honoo'));
      await tester.pumpAndSettle();
    }

    // Inserisci e pubblica
    final tf = find.byType(TextField).first;
    await tester.enterText(tf, '“Ciao luna”');
    if (find.text('Pubblica').evaluate().isNotEmpty) {
      await tester.tap(find.text('Pubblica'));
      await tester.pumpAndSettle();
    }

    // Apri dettaglio e rispondi (labels adattati alla tua UI)
    if (find.text('Rispondi').evaluate().isNotEmpty) {
      await tester.tap(find.text('Rispondi'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '“risposta”');
      await tester.tap(find.text('Invia'));
      await tester.pumpAndSettle();

      // verifica presenza 'risposta' a schermo
      expect(find.textContaining('risposta', findRichText: true), findsWidgets);
    }
  });
}
