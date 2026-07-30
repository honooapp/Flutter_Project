// test/pages/new_honoo_page_smoke_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Pages/new_honoo_page.dart';
import 'package:honoo/Entities/honoo.dart';
import 'package:honoo/UI/honoo_builder.dart';
import 'package:sizer/sizer.dart';

void main() {
  testWidgets('NewHonooPage si costruisce e accetta input di testo', (
    tester,
  ) async {
    await tester.pumpWidget(
      Sizer(
        builder: (context, orientation, deviceType) {
          return const MaterialApp(home: NewHonooPage());
        },
      ),
    );
    await tester.pumpAndSettle();

    final tf = find.byType(TextField).first;
    expect(tf, findsOneWidget);

    await tester.enterText(tf, '“Ciao luna”');
    await tester.pump();

    final controls = find.byKey(const Key('honoo-editor-controls'));
    final counter = find.byKey(const Key('honoo-editor-character-counter'));
    final builder = find.byType(HonooBuilder);

    expect(controls, findsOneWidget);
    expect(counter, findsOneWidget);
    expect(
      tester.getBottomLeft(controls).dy,
      lessThanOrEqualTo(tester.getTopLeft(builder).dy),
    );
    expect(tester.widget<Text>(counter).style?.color, Colors.white);
    expect(find.byTooltip('Salva sul dispositivo'), findsOneWidget);
    expect(find.byTooltip('Cancella honoo'), findsOneWidget);

    final builderRect = tester.getRect(builder);
    final footerRect = tester.getRect(
      find.byKey(const Key('honoo-editor-footer')),
    );
    final homeRect = tester.getRect(find.byTooltip('Home'));
    final hinooRect = tester.getRect(find.byTooltip('Scrivi hinoo'));
    expect(footerRect.top, greaterThanOrEqualTo(builderRect.bottom));
    expect(footerRect.top - builderRect.bottom, lessThan(16));
    expect(homeRect.left, greaterThanOrEqualTo(builderRect.left));
    expect(hinooRect.right, lessThanOrEqualTo(builderRect.right));
    expect(
      homeRect.left - builderRect.left,
      closeTo(builderRect.right - hinooRect.right, 0.01),
    );

    // bottone di pubblicazione presente (adatta label se diverso)
    expect(find.byTooltip('Salva honoo'), findsOneWidget);
  });

  testWidgets('il footer della risposta non mostra Scrivi hinoo', (
    tester,
  ) async {
    await tester.pumpWidget(
      Sizer(
        builder: (context, orientation, deviceType) {
          return const MaterialApp(
            home: NewHonooPage(forcedType: HonooType.answer),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Scrivi hinoo'), findsNothing);
    expect(find.byTooltip('Home'), findsOneWidget);
    expect(find.byTooltip('Apri il tuo Cuore'), findsOneWidget);
    expect(find.byTooltip('Invia'), findsOneWidget);
  });
}
