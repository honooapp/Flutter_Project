import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Pages/new_hinoo_page.dart';
import 'package:honoo/UI/hinoo_builder.dart';
import 'package:sizer/sizer.dart';

void main() {
  testWidgets('il footer hinoo non mostra Scrivi honoo', (tester) async {
    await tester.pumpWidget(
      Sizer(
        builder: (context, orientation, deviceType) {
          return const MaterialApp(home: NewHinooPage());
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Scrivi honoo'), findsNothing);
    expect(find.byTooltip('Home'), findsOneWidget);
    expect(find.byTooltip('Apri il tuo Cuore'), findsOneWidget);
  });

  testWidgets('il cestino hinoo non è mostrato sopra il box di editing', (
    tester,
  ) async {
    await tester.pumpWidget(
      Sizer(
        builder: (context, orientation, deviceType) {
          return const MaterialApp(home: NewHinooPage());
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Cancella hinoo'), findsNothing);
    expect(find.byType(HinooBuilder), findsOneWidget);
  });

  testWidgets('salvataggio immagine a sinistra e download nel footer', (
    tester,
  ) async {
    await tester.pumpWidget(
      Sizer(
        builder: (context, orientation, deviceType) {
          return const MaterialApp(home: NewHinooPage());
        },
      ),
    );
    await tester.pumpAndSettle();

    final dynamic pageState = tester.state(find.byType(NewHinooPage));
    pageState.setEditorStateForTesting(step: 'changeBg', hasBackground: true);
    await tester.pump();

    final saveImage = find.byTooltip('Salva immagine');
    final replaceImage = find.byTooltip('Sostituisci immagine');
    expect(saveImage, findsOneWidget);
    expect(replaceImage, findsOneWidget);
    expect(
      tester.getCenter(saveImage).dx,
      lessThan(tester.getCenter(replaceImage).dx),
    );

    pageState.setEditorStateForTesting(step: 'writeText', hasBackground: true);
    await tester.pump();

    expect(find.byTooltip('Salva sul dispositivo'), findsOneWidget);
    expect(find.byTooltip('Salva immagine'), findsNothing);
    expect(find.byTooltip('Salva hinoo'), findsNothing);

    pageState.setEditorStateForTesting(
      step: 'writeText',
      hasBackground: true,
      textLength: 1,
    );
    await tester.pump();

    expect(find.byTooltip('Salva hinoo'), findsOneWidget);
    expect(find.byTooltip('Salva sul dispositivo'), findsOneWidget);
    expect(
      tester.getCenter(find.byTooltip('Salva hinoo')).dx,
      lessThan(tester.getCenter(find.byTooltip('Salva sul dispositivo')).dx),
    );
  });
}
