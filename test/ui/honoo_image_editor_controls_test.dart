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
              child: HonooBuilder(key: key),
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
    final confirm = find.byKey(const Key('honoo-confirm-editing-image'));

    expect(
      find.text(
        'Trascina per spostare l’immagine.\n'
        'Usa il pizzico o i controlli per zoomare',
      ),
      findsOneWidget,
    );
    expect(replace, findsOneWidget);
    expect(confirm, findsOneWidget);
    expect(tester.getCenter(replace).dx, lessThan(tester.getCenter(panel).dx));
    expect(
      tester.getCenter(confirm).dx,
      closeTo(tester.getCenter(panel).dx, 0.5),
    );
  });
}
