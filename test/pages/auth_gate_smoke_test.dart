import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Pages/auth_gate.dart';
import 'package:honoo/Pages/home_page.dart';

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

  testWidgets('AuthGate: senza sessione mostra subito la home', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthGate()));

    expect(find.byType(HomePage), findsOneWidget);
  });
}
