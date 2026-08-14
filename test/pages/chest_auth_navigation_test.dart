import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Pages/chest_page.dart';
import 'package:honoo/Pages/email_login_page.dart';

import '../test_supabase_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(registerSupabaseFallbacks);

  late SupabaseTestHarness supabase;

  setUp(() {
    supabase = SupabaseTestHarness();
    supabase.enableOverrides();
  });

  tearDown(() => supabase.disableOverrides());

  testWidgets('lo Scrigno apre direttamente il login per un anonimo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => const ChestPage()),
              ),
              child: const Text('Apri Scrigno'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Apri Scrigno'));
    await tester.pumpAndSettle();

    expect(find.byType(EmailLoginPage), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
