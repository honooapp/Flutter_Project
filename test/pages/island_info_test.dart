import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/IsolaDelleStorie/Pages/island_page.dart';
import 'package:honoo/Utility/formatted_text.dart';
import 'package:sizer/sizer.dart';

void main() {
  testWidgets('Info Isola mostra i due esempi nei punti richiesti', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      Sizer(
        builder: (context, orientation, deviceType) =>
            const MaterialApp(home: IslandPage()),
      ),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Info'));
    await tester.pump();

    final infoContent = find.byKey(const Key('island_info_content'));
    expect(infoContent, findsOneWidget);
    expect(
      find.descendant(
        of: infoContent,
        matching: find.byKey(const Key('island_info_honoo_example')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: infoContent,
        matching: find.byKey(const Key('island_info_hinoo_example')),
      ),
      findsOneWidget,
    );

    final textParts = tester
        .widgetList<FormattedText>(
          find.descendant(of: infoContent, matching: find.byType(FormattedText)),
        )
        .map((widget) => widget.inputText)
        .toList();
    expect(textParts, hasLength(3));
    expect(textParts.first.trimRight(), endsWith('in forme più complesse'));
    expect(textParts[1].trimRight(), endsWith('<b>bianco<b> o <b>nero<b>'));
    expect(textParts.last.trim(), isNotEmpty);
    expect(textParts.join(), isNot(contains('.')));
  });
}
