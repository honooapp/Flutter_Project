import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:honoo/Pages/EmailLoginPage.dart'; // adatta path se serve
import 'package:honoo/Pages/EmailVerifyPage.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('EmailLoginPage: mostra errore per email vuota/invalid',
      (tester) async {
    // Avvia la pagina usando l'helper con Sizer (oppure usa MyApp completo se preferisci)
    // await tester.pumpWidget(const MyApp());
    await pumpSizerApp(tester, const EmailLoginPage());

    final emailField = find.byType(TextField);
    expect(emailField, findsOneWidget);

    // Inserisci solo spazi: l'email viene trim-ata prima dell'invio
    await tester.enterText(emailField, '   ');

    final sendBtn = find.widgetWithText(ElevatedButton, 'Invia codice');
    expect(sendBtn, findsOneWidget);

    await tester.tap(sendBtn);
    await tester.pumpAndSettle();

    final verifyPageFinder = find.byType(EmailVerifyPage);
    expect(verifyPageFinder, findsOneWidget);

    final verifyPage = tester.firstWidget<EmailVerifyPage>(verifyPageFinder);
    expect(verifyPage.email, isEmpty);
  });
}
