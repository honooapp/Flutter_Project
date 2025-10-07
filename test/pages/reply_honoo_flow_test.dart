import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:honoo/Pages/ReplyHonooPage.dart';
import 'package:honoo/Entities/Honoo.dart';
import 'package:sizer/sizer.dart';

import '../test_supabase_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseTestHarness harness;

  setUpAll(registerSupabaseFallbacks);

  setUp(() {
    harness = SupabaseTestHarness(withAuthenticatedUser: true);
    harness.enableOverrides();
    harness.stubTable('honoo');
  });

  tearDown(() {
    harness.disableOverrides();
  });

  testWidgets('ReplyHonooPage: si costruisce, accetta input e mostra azione di invio',
      (tester) async {
    final original = Honoo(
      1,
      '“Testo origine”',
      '',
      '2024-01-01T00:00:00Z',
      '2024-01-01T00:00:00Z',
      'user_1',
      HonooType.personal,
    );

    await tester.pumpWidget(
      Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            home: ReplyHonooPage(
              originalHonoo: original,
            ),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    final tf = find.byType(TextField).first;
    expect(tf, findsOneWidget);

    await tester.enterText(tf, '“risposta di prova”');
    await tester.pump();

    final sendButton = find.textContaining('Invia', findRichText: true);
    expect(sendButton, findsWidgets);

    await tester.tap(sendButton.first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });
}
