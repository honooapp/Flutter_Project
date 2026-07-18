import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Entities/casa_share_mode.dart';
import 'package:honoo/Entities/knock_message_choice.dart';
import 'package:honoo/Widgets/casa_share_dialogs.dart';
import 'package:honoo/Widgets/knock_message_dialog.dart';

void main() {
  testWidgets('scelta messaggio restituisce Hinoo su viewport mobile',
      (tester) async {
    KnockMessageChoice? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDialog<KnockMessageChoice>(
                context: context,
                builder: (_) => const KnockMessageDialog(),
              );
            },
            child: const Text('Apri'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();
    expect(find.text('Vuoi inviare un messaggio\nprima di bussare?'),
        findsOneWidget);
    await tester.tap(find.text('Scrivi un hinoo'));
    await tester.pumpAndSettle();
    expect(result, KnockMessageChoice.hinoo);
  });

  testWidgets('condivisione multipla salva la selezione', (tester) async {
    Set<CasaShareMode>? saved;
    Set<CasaShareMode>? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDialog<Set<CasaShareMode>>(
                context: context,
                builder: (_) => CasaMultiShareDialog(
                  onConfirm: (modes) async => saved = Set.of(modes),
                ),
              );
            },
            child: const Text('Apri'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(CasaShareMode.honoo.label));
    await tester.tap(find.text(CasaShareMode.hinoo.label));
    await tester.pump();
    await tester.tap(find.text('Condividi'));
    await tester.pumpAndSettle();

    expect(saved, {CasaShareMode.honoo, CasaShareMode.hinoo});
    expect(result, saved);
  });

  testWidgets('visitatore sceglie il contenuto su viewport desktop',
      (tester) async {
    CasaShareMode? result;
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDialog<CasaShareMode>(
                context: context,
                builder: (_) => const VisitorShareChoiceDialog(
                  modes: {
                    CasaShareMode.honoo,
                    CasaShareMode.conversations,
                  },
                ),
              );
            },
            child: const Text('Apri'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text(CasaShareMode.conversations.label));
    await tester.pumpAndSettle();
    expect(result, CasaShareMode.conversations);
  });
}
