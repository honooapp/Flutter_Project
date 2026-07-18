import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Widgets/house_invite_dialogs.dart';

void main() {
  testWidgets('richiesta inviata mostra email e si chiude', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      return TextButton(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const HouseRequestSentDialog(
            email: 'utente@example.com',
          ),
        ),
        child: const Text('Apri'),
      );
    })));
    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();
    expect(find.text('utente@example.com ha richiesto una casa sull\'Isola.'),
        findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Richiesta inviata'), findsNothing);
  });

  testWidgets('richiesta ricevuta restituisce Invita', (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      return TextButton(
        onPressed: () async {
          result = await showDialog<bool>(
            context: context,
            builder: (_) => const HouseRequestReceivedDialog(email: ''),
          );
        },
        child: const Text('Apri'),
      );
    })));
    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();
    expect(find.text('Un utente ha richiesto una casa sull\'Isola.'),
        findsOneWidget);
    await tester.tap(find.text('Invita'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
