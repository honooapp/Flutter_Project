import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Pages/placeholder_page.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Widgets/honoo_app_title.dart';

void main() {
  testWidgets('il titolo honoo e rosso e apre la pagina principale', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: HonooAppTitle())),
      ),
    );

    final AnimatedDefaultTextStyle titleStyle = tester.widget(
      find.descendant(
        of: find.byType(HonooAppTitle),
        matching: find.byType(AnimatedDefaultTextStyle),
      ),
    );
    expect(titleStyle.style.color, HonooColor.secondary);

    await tester.tap(find.byType(HonooAppTitle));
    await tester.pumpAndSettle();

    expect(find.byType(PlaceholderPage), findsOneWidget);
  });
}
