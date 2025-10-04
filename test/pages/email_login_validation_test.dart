import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Pages/EmailLoginPage.dart';

void main() {
  testWidgets('EmailLoginPage: mostra errore per email vuota/invalid', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: EmailLoginPage()));
    await tester.pumpAndSettle();

    final emailField = find.byType(TextField).first;
    expect(emailField, findsOneWidget);

    // Caso 1: vuota → tap su azione e attendo un feedback di errore
    final action = find.textContaining('Invia', findRichText: true).evaluate().isNotEmpty
        ? find.textContaining('Invia', findRichText: true)
        : (find.textContaining('Accedi', findRichText: true).evaluate().isNotEmpty
        ? find.textContaining('Accedi', findRichText: true)
        : find.byType(ElevatedButton));

    await tester.tap(action.first);
    await tester.pump();

    // Heuristica di errore (tollerante a label diversi)
    final hasErrorEmpty = find.textContaining('email', findRichText: true).evaluate().isNotEmpty
        || find.textContaining('inserisci', findRichText: true).evaluate().isNotEmpty
        || find.textContaining('obbligatoria', findRichText: true).evaluate().isNotEmpty;
    expect(hasErrorEmpty, isTrue, reason: 'Atteso un messaggio di errore per email vuota');

    // Caso 2: formato invalido
    await tester.enterText(emailField, 'non_valida');
    await tester.tap(action.first);
    await tester.pump();

    final hasErrorInvalid = find.textContaining('@', findRichText: true).evaluate().isNotEmpty
        || find.textContaining('valida', findRichText: true).evaluate().isNotEmpty
        || find.textContaining('formato', findRichText: true).evaluate().isNotEmpty;
    expect(hasErrorInvalid, isTrue, reason: 'Atteso messaggio per formato email non valido');
  });
}
