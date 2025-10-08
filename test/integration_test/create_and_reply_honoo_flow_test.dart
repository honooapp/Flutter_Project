import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:honoo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'crea honoo e poi rispondi',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Verifica che la conversazione mostri l'honoo appena creato
      expect(find.textContaining('ciao luna'), findsWidgets);

      // Apri il composer di risposta
      final replyButton = find.byTooltip('Rispondi');
      await tester.tap(replyButton.first);
      await tester.pumpAndSettle();

      // Compila la risposta
      final replyField = find.byType(TextField).first;
      await tester.enterText(replyField, 'risposta di test');

      // Invia la risposta
      final sendButton = find.text('Invia risposta');
      await tester.tap(sendButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Controlla che la risposta compaia nella conversazione
      expect(find.textContaining('risposta di test'), findsWidgets);
    },
    tags: ['integration'],
  );
}
