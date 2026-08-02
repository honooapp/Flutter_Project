import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Widgets/honoo_dialogs.dart';

void main() {
  testWidgets('i dialoghi rimuovono il punto finale dai testi di interfaccia', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HonooConfirmDialog(
            title: 'Titolo.',
            message: 'Messaggio conclusivo.',
            confirmLabel: 'Conferma',
          ),
        ),
      ),
    );

    expect(find.text('Titolo'), findsOneWidget);
    expect(find.text('Messaggio conclusivo'), findsOneWidget);
    expect(find.text('Titolo.'), findsNothing);
    expect(find.text('Messaggio conclusivo.'), findsNothing);
  });
}
