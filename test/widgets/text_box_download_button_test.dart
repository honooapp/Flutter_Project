import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Widgets/text_box_download_button.dart';

void main() {
  testWidgets('nasconde il pulsante soltanto durante la cattura',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextBoxDownloadButton(onPressed: () {}),
        ),
      ),
    );
    expect(find.byIcon(Icons.download_outlined), findsOneWidget);

    final Completer<void> captureStarted = Completer<void>();
    final Completer<void> finishCapture = Completer<void>();
    final Future<void> capture = TextBoxDownloadButton.hideWhileCapturing(
      () async {
        captureStarted.complete();
        await finishCapture.future;
      },
    );

    await tester.pump();
    await captureStarted.future;
    expect(tester.widget<Visibility>(find.byType(Visibility)).visible, isFalse);

    finishCapture.complete();
    await capture;
    await tester.pump();
    expect(tester.widget<Visibility>(find.byType(Visibility)).visible, isTrue);
    expect(find.byIcon(Icons.download_outlined), findsOneWidget);
  });
}
