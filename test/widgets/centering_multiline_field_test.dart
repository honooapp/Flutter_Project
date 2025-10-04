import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Widgets/centering_multiline_field.dart';

void main() {
  testWidgets('wrap automatico entro 3 righe senza overflow', (tester) async {
    const testoLungo =
        'Questo è un testo molto lungo che deve andare a capo automaticamente fino '
        'a tre righe senza generare overflow laterale.';

    final controller = TextEditingController(text: testoLungo);
    const style = TextStyle(fontSize: 16);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: CenteringMultilineField(
              controller: controller,
              style: style,
              maxLines: 3,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(CenteringMultilineField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
