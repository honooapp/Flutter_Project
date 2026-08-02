import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/UI/HinooBuilder/overlays/cambia_sfondo.dart';

void main() {
  testWidgets('la barra zoom hinoo replica lo stile compatto honoo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CambiaSfondoOverlay(
            onTapChange: () {},
            showControls: true,
            isUploading: true,
            onScaleChanged: (_) {},
            useCompactControls: true,
          ),
        ),
      ),
    );

    final Finder sliderFinder = find.byKey(
      const Key('hinoo-image-zoom-slider'),
    );
    expect(sliderFinder, findsOneWidget);
    expect(find.text('Caricamento immagine…'), findsOneWidget);
    expect(find.byIcon(Icons.remove), findsNothing);
    expect(find.byIcon(Icons.add), findsNothing);

    final SliderTheme sliderTheme = tester.widget<SliderTheme>(
      find.ancestor(of: sliderFinder, matching: find.byType(SliderTheme)).first,
    );
    expect(sliderTheme.data.thumbColor, Colors.white);
    expect(sliderTheme.data.trackHeight, 2);
  });

  testWidgets('l’indicazione iniziale hinoo è ingrandita di un punto', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CambiaSfondoOverlay(onTapChange: () {})),
      ),
    );

    final Text prompt = tester.widget<Text>(
      find.text('Carica prima la tua immagine,\n e poi scrivi il tuo testo'),
    );
    expect(prompt.style?.fontSize, 17);
  });
}
