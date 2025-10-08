// test/pages/new_honoo_page_smoke_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Pages/new_honoo_page.dart';
import 'package:sizer/sizer.dart';

void main() {
  testWidgets('NewHonooPage si costruisce e accetta input di testo',
      (tester) async {
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

    // bottone di pubblicazione presente (adatta label se diverso)
    expect(find.byTooltip('Salva honoo'), findsOneWidget);
  });
}
