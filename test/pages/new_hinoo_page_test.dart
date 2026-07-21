import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Pages/new_hinoo_page.dart';
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
}
