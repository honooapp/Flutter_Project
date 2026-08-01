// test/pages/new_honoo_page_smoke_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Pages/new_honoo_page.dart';
import 'package:honoo/Entities/honoo.dart';
import 'package:honoo/UI/honoo_builder.dart';
import 'package:honoo/Widgets/width_limited_multiline_field.dart';
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

    final counter = find.byKey(const Key('honoo-editor-character-counter'));
    final builder = find.byType(HonooBuilder);
    final textArea = find.byKey(const Key('honoo-text-area'));

    expect(find.byKey(const Key('honoo-editor-controls')), findsNothing);
    expect(counter, findsOneWidget);
    expect(
      tester.getCenter(counter).dx,
      closeTo(tester.getCenter(builder).dx, 0.01),
    );
    expect(
      tester.getBottomLeft(counter).dy,
      closeTo(tester.getBottomLeft(textArea).dy - 8, 1),
    );
    expect(
      tester
          .widget<WidthLimitedMultilineField>(
            find.byType(WidthLimitedMultilineField),
          )
          .horizontalPadding
          .bottom,
      24,
    );
    expect(find.byTooltip('Salva sul dispositivo'), findsOneWidget);
    expect(find.byTooltip('Cancella honoo'), findsNothing);

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

    expect(find.byTooltip('Salva honoo'), findsNothing);
    expect(
      tester.getCenter(find.byTooltip('Scrivi hinoo')).dx,
      lessThan(tester.getCenter(find.byTooltip('Salva sul dispositivo')).dx),
    );
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
    expect(find.byTooltip('Invia'), findsNothing);
    expect(find.byTooltip('Salva sul dispositivo'), findsOneWidget);
  });
}
