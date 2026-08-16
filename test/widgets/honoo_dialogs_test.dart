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

  testWidgets('la ripubblicazione sulla Luna richiede una scelta Sì o No', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showRepeatMoonPublicationDialog(
                context,
                contentName: 'honoo',
              );
            },
            child: const Text('Apri'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Questo honoo è già presente sulla Luna, vuoi inviarlo di nuovo?',
      ),
      findsOneWidget,
    );
    expect(find.text('Sì'), findsOneWidget);
    expect(find.text('No'), findsOneWidget);

    await tester.tap(find.text('Sì'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
