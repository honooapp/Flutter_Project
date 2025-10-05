import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:honoo/Pages/EmailLoginPage.dart'; // adatta se il path è diverso

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('EmailLoginPage: render, input email e azione presente', (tester) async {
    // Avvia la pagina o l'app intera (scegline UNA delle due righe)
    // await tester.pumpWidget(const MyApp());
    await tester.pumpWidget(const MaterialApp(home: EmailLoginPage()));

    await tester.pumpAndSettle();

    // 1) Digita l'email
    final emailField = find.byType(TextField);
    expect(emailField, findsWidgets);
    await tester.enterText(emailField.first, 'ciao@example.com');

    final sendBtn = find.byKey(const Key('email_send_code_btn'));
    expect(sendBtn, findsOneWidget);
    await tester.ensureVisible(sendBtn);
    await tester.tap(sendBtn, warnIfMissed: false);
    await tester.pumpAndSettle();


    expect(sendBtn, findsOneWidget);

    // Se è offstage, scrolla/assicurati sia visibile
    await tester.ensureVisible(sendBtn);

    // 3) Tap (niente warning se offstage)
    await tester.tap(sendBtn, warnIfMissed: false);
    await tester.pumpAndSettle();

    // 4) Se si apre un dialog, chiudilo per evitare timer pendenti
    final okBtn = find.widgetWithText(TextButton, 'OK');
    if (okBtn.evaluate().isNotEmpty) {
      await tester.tap(okBtn);
      await tester.pumpAndSettle();
    }

    // 5) Lascia scadere eventuali Timer (es. 1.2s in honoo_dialogs)
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });
}
