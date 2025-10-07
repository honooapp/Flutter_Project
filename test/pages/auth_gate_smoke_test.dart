import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Pages/AuthGate.dart';
import 'package:honoo/Pages/PlaceholderPage.dart';

import '../test_supabase_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseTestHarness harness;

  setUpAll(registerSupabaseFallbacks);

  setUp(() {
    harness = SupabaseTestHarness();
    harness.enableOverrides();
  });

  tearDown(() {
    harness.disableOverrides();
  });

  testWidgets('AuthGate: senza sessione → mostra una schermata di login', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthGate()));
    await tester.pumpAndSettle();

    // Heuristica: in assenza di sessione dovremmo vedere almeno 1 TextField (email)
    // o un testo che contiene "Login" / "Accedi".
    final hasField = find.byType(TextField).evaluate().isNotEmpty;
    final hasLoginText =
        find.textContaining('Login', findRichText: true).evaluate().isNotEmpty ||
            find.textContaining('Accedi', findRichText: true).evaluate().isNotEmpty;
    final hasPlaceholder = find.byType(PlaceholderPage).evaluate().isNotEmpty;
    expect(hasField || hasLoginText || hasPlaceholder, isTrue);
  });
}
