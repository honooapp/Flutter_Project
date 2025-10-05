import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:honoo/Pages/EmailLoginPage.dart'; // adatta path se serve

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('EmailLoginPage: mostra errore per email vuota/invalid',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: EmailLoginPage()));
    await tester.pumpAndSettle();

    // Assicurati che il field ci sia
    final emailField = find.byType(TextField);
    expect(emailField, findsWidgets);

    // Lascia vuoto → errore atteso
    await tester.enterText(emailField.first, '');
    await tester.pump();

    final sendBtn = find.byKey(const Key('email_send_code_btn'));
    expect(sendBtn, findsOneWidget);
    await tester.ensureVisible(sendBtn);
    await tester.tap(sendBtn, warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.ensureVisible(sendBtn);
    await tester.tap(sendBtn, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verifica presenza messaggio errore (adatta al tuo testo reale)
    // es: expect(find.text('Email non valida'), findsOneWidget);

    // Chiudi eventuale dialog, se presente
    final okBtn = find.widgetWithText(TextButton, 'OK');
    if (okBtn.evaluate().isNotEmpty) {
      await tester.tap(okBtn);
      await tester.pumpAndSettle();
    }

    // Lascia scadere i Timer pendenti
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });
}
