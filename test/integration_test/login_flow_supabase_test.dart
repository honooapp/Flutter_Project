import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:honoo/main.dart';

// ATTENZIONE:
// - Questo test chiama davvero Supabase. Va abilitato SOLO in locale con un progetto di test.
// - Per eseguirlo in locale, togli lo "skip: true" in fondo e assicurati di avere le env corrette.

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Login flow end-to-end (magic link o email/password)',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Trova campo email nella schermata di login
      final emailField = find.byType(TextField).first;
      expect(emailField, findsOneWidget);

      // Inserisci un'email di test (deve essere valida nel tuo Supabase di test)
      await tester.enterText(emailField, 'test-user@example.com');
      await tester.pump();

      // Tappa su "Invia" / "Accedi"
      final hasInvia = find
          .textContaining('Invia', findRichText: true)
          .evaluate()
          .isNotEmpty;
      final action = hasInvia
          ? find.textContaining('Invia', findRichText: true)
          : find.textContaining('Accedi', findRichText: true);

      await tester.tap(action.first);
      await tester.pumpAndSettle();

      // Heuristica: dopo l'invio potresti navigare a EmailVerifyPage o mostrare un messaggio di conferma.
      final hasVerify = find
              .textContaining('verifica', findRichText: true)
              .evaluate()
              .isNotEmpty ||
          find
              .textContaining('controlla', findRichText: true)
              .evaluate()
              .isNotEmpty;
      expect(hasVerify, isTrue);
    },
    tags: ['integration'],
    skip: true,
  );
}
