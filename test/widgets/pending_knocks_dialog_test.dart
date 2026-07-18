import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Entities/pending_knock.dart';
import 'package:honoo/Widgets/pending_knocks_dialog.dart';

void main() {
  testWidgets('mostra le bussate e apre quella selezionata', (tester) async {
    final knocks = [
      PendingKnock(
        id: 'knock-1',
        targetTag: 'house-1',
        createdAt: DateTime.utc(2026, 7, 18, 12),
      ),
    ];
    PendingKnock? opened;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => PendingKnocksDialog(
                knocks: knocks,
                labelForKnock: (_) => 'Casa del test',
                timestampForKnock: (_) => '18/07/2026 12:00',
                onOpen: (knock) async => opened = knock,
              ),
            ),
            child: const Text('Apri'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();

    expect(find.byType(PendingKnocksDialog), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('Bussate in attesa'), findsOneWidget);
    expect(find.text('Casa del test'), findsOneWidget);
    expect(find.text('18/07/2026 12:00'), findsOneWidget);

    await tester.tap(find.text('Casa del test'));
    await tester.pumpAndSettle();

    expect(opened?.id, 'knock-1');
    expect(find.byType(PendingKnocksDialog), findsNothing);
  });

  testWidgets('il pulsante Chiudi chiude il dialogo senza aprire bussate',
      (tester) async {
    var opened = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => PendingKnocksDialog(
                knocks: const [],
                labelForKnock: (_) => '',
                timestampForKnock: (_) => '',
                onOpen: (_) async => opened = true,
              ),
            ),
            child: const Text('Apri'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chiudi'));
    await tester.pumpAndSettle();

    expect(opened, isFalse);
    expect(find.byType(PendingKnocksDialog), findsNothing);
  });
}
