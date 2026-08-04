import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/UI/HinooBuilder/overlays/scrivi_hinoo.dart';

void main() {
  testWidgets('applica le sostituzioni tipografiche nell editor Hinoo', (
    tester,
  ) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 500,
            height: 760,
            child: Stack(
              children: [
                ScriviHinooOverlay(
                  controller: controller,
                  focusNode: focusNode,
                  textColor: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(EditableText), '-- ... << >>\n');
    await tester.pump();

    expect(controller.text, '— … « »\n');
  });
}
