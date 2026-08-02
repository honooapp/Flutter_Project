import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/UI/HinooBuilder/overlays/cambia_sfondo.dart';

void main() {
  testWidgets('i controlli hinoo usano la terminologia immagine', (
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
            onZoomIn: () {},
            onZoomOut: () {},
          ),
        ),
      ),
    );

    expect(
      find.text(
        'Trascina per spostare l’immagine\n'
        'Usa il pizzico o i controlli per zoomare',
      ),
      findsOneWidget,
    );
    expect(find.text('Caricamento immagine…'), findsOneWidget);
    expect(find.text('Sostituisci immagine'), findsOneWidget);
    expect(find.textContaining('sfondo'), findsNothing);
    expect(find.byTooltip('Reimposta posizione'), findsNothing);
  });

  testWidgets('Sostituisci immagine è centrato nel pannello hinoo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CambiaSfondoOverlay(
            onTapChange: () {},
            showControls: true,
            onScaleChanged: (_) {},
            onZoomIn: () {},
            onZoomOut: () {},
          ),
        ),
      ),
    );

    final Finder button = find.widgetWithText(
      TextButton,
      'Sostituisci immagine',
    );
    final Finder panel = find.byKey(const Key('hinoo-image-editing-controls'));

    expect(button, findsOneWidget);
    expect(
      tester.getCenter(button).dx,
      closeTo(tester.getCenter(panel).dx, 0.5),
    );
  });
}
