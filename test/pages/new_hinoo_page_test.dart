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

  testWidgets('il cestino hinoo è sopra e fuori dal box di editing', (
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

    final Finder deleteButton = find.byTooltip('Cancella hinoo');
    final Finder editor = find.byType(HinooBuilder);

    expect(deleteButton, findsOneWidget);
    expect(editor, findsOneWidget);
    expect(
      tester.getBottomLeft(deleteButton).dy,
      lessThanOrEqualTo(tester.getTopLeft(editor).dy),
    );
  });
}
