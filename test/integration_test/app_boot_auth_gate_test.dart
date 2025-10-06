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
    'boot → mostra login o home senza crash',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Prova a riconoscere la schermata tramite Key (più stabile)
      final loginByKey = find.byKey(const Key('login_screen_root'));
      final homeByKey = find.byKey(const Key('home_screen_root'));

      final loginFoundByKey = loginByKey.evaluate().isNotEmpty;
      final homeFoundByKey = homeByKey.evaluate().isNotEmpty;

      // Fallback: controlla per testo (meno stabile, ma utile se le Key non ci sono)
      final loginByText = find.textContaining('Login', findRichText: true);
      final homeByText = find.textContaining('Home', findRichText: true);

      final loginFoundByText = loginByText.evaluate().isNotEmpty;
      final homeFoundByText = homeByText.evaluate().isNotEmpty;

      expect(
        loginFoundByKey ||
            homeFoundByKey ||
            loginFoundByText ||
            homeFoundByText,
        isTrue,
        reason: 'Non ho trovato né la schermata di Login né la Home. Aggiungi '
            'Key(\'login_screen_root\') / Key(\'home_screen_root\') ai widget di root per test più stabili.',
      );
    },
    tags: ['integration'],
  );
}
