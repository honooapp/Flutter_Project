import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/IsolaDelleStorie/Pages/island_page.dart';
import 'package:honoo/Utility/formatted_text.dart';
import 'package:sizer/sizer.dart';

void main() {
  testWidgets('Info Isola mostra il secondo esempio dopo bianco o nero', (
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
          find.descendant(
            of: infoContent,
            matching: find.byType(FormattedText),
          ),
        )
        .map((widget) => widget.inputText)
        .toList();
    expect(textParts, hasLength(3));
    expect(textParts.first.trimRight(), endsWith('in forme più complesse'));
    expect(textParts[1].trimRight(), endsWith('<b>bianco<b> o <b>nero<b>'));
    expect(textParts.last.trim(), isNotEmpty);
    expect(textParts.join(), isNot(contains('.')));

    final infoColumn = tester.widget<Column>(infoContent);
    final hinooExampleIndex = infoColumn.children.indexWhere(
      (child) => child.key == const Key('island_info_hinoo_example'),
    );
    final formattedTextIndexes = <int>[
      for (var index = 0; index < infoColumn.children.length; index++)
        if (infoColumn.children[index] is FormattedText) index,
    ];
    expect(hinooExampleIndex, greaterThan(formattedTextIndexes[1]));
    expect(hinooExampleIndex, lessThan(formattedTextIndexes[2]));
    final hinooImage = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const Key('island_info_hinoo_example')),
        matching: find.byType(Image),
      ),
    );
    expect(
      (hinooImage.image as AssetImage).assetName,
      'assets/images/onboarding_hinoo.png',
    );
  });

  for (final size in <Size>[
    const Size(320, 568),
    const Size(390, 844),
    const Size(1024, 768),
  ]) {
    testWidgets('toolbar Isola resta responsive a ${size.width.toInt()} px', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) =>
              const MaterialApp(home: IslandPage()),
        ),
      );
      await tester.pump();

      final bottle = find.byKey(const Key('island_footer_bottle'));
      final chest = find.byKey(const Key('island_footer_chest'));
      final info = find.byKey(const Key('island_footer_info'));

      expect(tester.widget<Positioned>(bottle).bottom, 27);
      expect(tester.widget<Positioned>(chest).bottom, -7);
      expect(tester.widget<Positioned>(info).bottom, -5);

      for (final icon in <Finder>[bottle, chest, info]) {
        final rect = tester.getRect(icon);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));
      }
      expect(tester.takeException(), isNull);
    });
  }
}
