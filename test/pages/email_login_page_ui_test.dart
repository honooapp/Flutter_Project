import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Pages/EmailLoginPage.dart';

void main() {
  testWidgets('EmailLoginPage: render, input email e azione presente', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: EmailLoginPage()));
    await tester.pumpAndSettle();

    // Deve esserci almeno un TextField per l'email
    final emailField = find.byType(TextField).first;
    expect(emailField, findsOneWidget);

    // Digita una email plausibile
    await tester.enterText(emailField, 'utente@example.com');
    await tester.pump();

    // Trova un bottone per inviare/magic link/login (etichette tolleranti)
    final action = find.textContaining('Invia', findRichText: true)
        .evaluate()
        .isNotEmpty
        ? find.textContaining('Invia', findRichText: true)
        : (find.textContaining('Accedi', findRichText: true).evaluate().isNotEmpty
        ? find.textContaining('Accedi', findRichText: true)
        : find.byType(ElevatedButton));

    expect(action, findsWidgets);

    // Tap: non verifichiamo la rete, solo che non crashi
    await tester.tap(action.first);
    await tester.pump();
  });
}
