import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/UI/honoo_builder.dart';
import 'package:honoo/Utility/responsive_layout.dart';

void main() {
  testWidgets('contatore e input Honoo si fermano a 144 caratteri', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 500,
            height: 760,
            child: HonooBuilder(showDownloadButton: false),
          ),
        ),
      ),
    );

    final field = find.byType(EditableText);
    expect(field, findsOneWidget);
    // Usa glifi stretti: il test isola il limite totale senza superare prima
    // il vincolo fisico di larghezza applicato a ogni riga.
    final line = List.filled(28, 'i').join();
    final accepted = List.filled(5, line).join('\n');
    expect(accepted.characters.length, HonooBuilder.maxTextCharacters);

    await tester.enterText(field, accepted);
    await tester.pump();
    await tester.enterText(field, '${accepted}x');
    await tester.pump();

    final editable = tester.widget<EditableText>(field);
    expect(
      editable.controller.text.characters.length,
      HonooBuilder.maxTextCharacters,
    );
    expect(find.text('144/144'), findsOneWidget);
  });

  testWidgets('applica le sostituzioni tipografiche nell editor Honoo', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 500,
            height: 760,
            child: HonooBuilder(showDownloadButton: false),
          ),
        ),
      ),
    );

    final field = find.byType(EditableText);
    await tester.enterText(field, '-- ... << >>\n');
    await tester.pump();

    final editable = tester.widget<EditableText>(field);
    expect(editable.controller.text, '— … « »\n');
  });

  test('OK immagine mantiene la stessa dimensione visiva del footer', () {
    for (final mode in ResponsiveLayoutMode.values) {
      final footerSize = ResponsiveLayout.footerIconSizeForMode(mode);
      for (final canvasScale in <double>[0.55, 0.8, 1.0, 1.35]) {
        final baselineSize = HonooBuilder.baselineIconSizeForDisplay(
          footerSize,
          canvasScale,
        );
        expect(baselineSize * canvasScale, closeTo(footerSize, 0.0001));
      }
    }
  });
}
