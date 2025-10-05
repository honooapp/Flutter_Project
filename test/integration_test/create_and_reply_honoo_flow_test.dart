@Tags(['integration'])

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:honoo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('crea honoo e poi rispondi', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Esempio robusto: controlla che il campo esista prima di usarlo
    final textField = find.byType(TextField);
    expect(textField, findsAtLeastNWidgets(1)); // evita "No element"
    await tester.enterText(textField.first, 'ciao luna');

    // Se hai un pulsante con Key o testo, usalo:
    final creaBtn = find.text('Crea'); // oppure find.byKey(const Key('btnCrea'))
    expect(creaBtn, findsOneWidget);
    await tester.tap(creaBtn);
    await tester.pumpAndSettle();

    // Verifica qualcosa a schermo dopo la creazione
    expect(find.textContaining('honoo'), findsWidgets);

    // … continua il flusso “rispondi” con gli stessi accorgimenti
  });
}
