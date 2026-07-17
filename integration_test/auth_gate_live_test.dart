import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:honoo/main.dart' as app;
import 'package:honoo/testing/live_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E: il bootstrap raggiunge landing o home', (tester) async {
    if (!LiveConfig.liveRun || !LiveConfig.isValid) {
      return;
    }

    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 12));

    final landing = find.byKey(const Key('public_landing_screen_root'));
    final home = find.byKey(const Key('home_screen_root'));
    expect(
      landing.evaluate().isNotEmpty || home.evaluate().isNotEmpty,
      isTrue,
      reason: 'Il bootstrap non ha raggiunto né la landing né la home.',
    );
  });
}
