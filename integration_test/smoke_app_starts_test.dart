import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:honoo/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('smoke: app shows first frame', (tester) async {
    try {
      app.main();
    } catch (_) {}
    await tester.pumpAndSettle(const Duration(seconds: 12));
    expect(find.byType(MaterialApp), findsWidgets);
  });
}
