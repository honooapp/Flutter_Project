import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/UI/honoo_builder.dart';

void main() {
  testWidgets('i controlli immagine honoo hanno il nuovo posizionamento', (
    tester,
  ) async {
    final key = GlobalKey<HonooBuilderState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              height: 549,
              child: HonooBuilder(key: key, initialText: 'Testo iniziale'),
            ),
          ),
        ),
      ),
    );

    key.currentState!.setImageBytesForTesting(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    );
    await tester.pumpAndSettle();

    final panel = find.byKey(const Key('honoo-image-editing-controls'));
    final replace = find.byKey(const Key('honoo-replace-editing-image'));
    final editText = find.byKey(const Key('honoo-edit-text'));
    final save = find.byKey(const Key('honoo-save'));

    expect(
      find.text(
        'Trascina per spostare l’immagine.\n'
        'Usa il pizzico o i controlli per zoomare',
      ),
      findsOneWidget,
    );
    expect(replace, findsOneWidget);
    expect(editText, findsOneWidget);
    expect(save, findsOneWidget);
    expect(tester.getCenter(replace).dx, lessThan(tester.getCenter(panel).dx));
    expect(
      tester.getCenter(editText).dx,
      greaterThan(tester.getCenter(panel).dx),
    );
    expect(
      tester.getCenter(replace).dy,
      closeTo(tester.getCenter(editText).dy, 0.5),
    );
    expect(tester.getCenter(save).dx, closeTo(tester.getCenter(panel).dx, 0.5));
    expect(
      tester.getCenter(save).dy,
      greaterThan(tester.getCenter(replace).dy),
    );
    expect(find.text('Salva honoo'), findsOneWidget);
  });

  testWidgets('Modifica testo conserva il testo e consente il ritorno', (
    tester,
  ) async {
    final key = GlobalKey<HonooBuilderState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              height: 549,
              child: HonooBuilder(key: key, initialText: 'Testo iniziale'),
            ),
          ),
        ),
      ),
    );

    key.currentState!.setImageBytesForTesting(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('honoo-edit-text')));
    await tester.pump();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Testo iniziale'), findsOneWidget);
    expect(find.byKey(const Key('honoo-image-editing-controls')), findsNothing);

    await tester.enterText(find.byType(TextField), 'Testo modificato');
    await tester.tap(find.byKey(const Key('honoo-image-area')));
    await tester.pump();

    expect(
      find.byKey(const Key('honoo-image-editing-controls')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('honoo-edit-text')), findsOneWidget);

    await tester.tap(find.byKey(const Key('honoo-edit-text')));
    await tester.pump();
    expect(find.text('Testo modificato'), findsOneWidget);
  });
}
