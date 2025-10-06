import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:honoo/main.dart';

void main() {
  final binding = WidgetsBinding.instance;
  if (binding is TestWidgetsFlutterBinding &&
      binding is! IntegrationTestWidgetsFlutterBinding) {
    return;
  }

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'crea honoo e poi rispondi',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Trova il primo TextField disponibile ed inserisci testo
      final textField = find.byType(TextField);
      expect(textField, findsAtLeastNWidgets(1));
      await tester.enterText(textField.first, 'ciao luna');

      // Tappa il pulsante “Crea” (se nella tua UI ha una Key, usa quella)
      final creaBtn = find.text(
          'Crea'); // oppure: find.byKey(const Key('email_send_code_btn'));
      expect(creaBtn, findsOneWidget);
      await tester.tap(creaBtn);
      await tester.pumpAndSettle();

      // Verifica un effetto a schermo dopo la creazione
      expect(find.textContaining('honoo'), findsWidgets);

      // TODO: prosegui con il flusso “rispondi” se necessario
    },
    tags: ['integration'],
  );
}
