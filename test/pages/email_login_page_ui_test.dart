import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:honoo/Pages/EmailLoginPage.dart'; // adatta se il path è diverso
import 'package:honoo/Pages/EmailVerifyPage.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('EmailLoginPage: render, input email e azione presente',
      (tester) async {
    // Avvia la pagina usando l'helper con Sizer (oppure usa MyApp completo se preferisci)
    // await tester.pumpWidget(const MyApp());
    await pumpSizerApp(tester, const EmailLoginPage());

    // 1) Digita l'email
    final emailField = find.byType(TextField);
    expect(emailField, findsOneWidget);
    await tester.enterText(emailField, 'ciao@example.com');

    expect(find.text('ciao@example.com'), findsOneWidget);

    final sendBtn = find.widgetWithText(ElevatedButton, 'Invia codice');
    expect(sendBtn, findsOneWidget);

    await tester.tap(sendBtn);
    await tester.pumpAndSettle();

    // Dopo la navigazione la pagina di verifica dovrebbe essere nello stack
    expect(find.byType(EmailVerifyPage), findsOneWidget);
  });
}
