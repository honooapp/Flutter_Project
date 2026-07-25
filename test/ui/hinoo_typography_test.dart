import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Entities/hinoo.dart';
import 'package:honoo/UI/hinoo_typography.dart';
import 'package:honoo/UI/hinoo_viewer.dart';

void main() {
  testWidgets('creation and publication use the Honoo-equivalent font size',
      (tester) async {
    final creationStyle = HinooTypography.textStyle(color: Colors.white);
    final publicationStyle =
        HinooTypography.displayTextStyle(color: Colors.white);

    expect(HinooTypography.fontSize, 18.0);
    expect(creationStyle.fontSize, HinooTypography.fontSize);
    expect(publicationStyle.fontSize, HinooTypography.fontSize);
    expect(creationStyle.height, HinooTypography.lineHeight);
    expect(publicationStyle.height, HinooTypography.lineHeight);
    expect(publicationStyle.fontWeight, creationStyle.fontWeight);
  });

  test('twenty lines remain inside the baseline Hinoo text area', () {
    final availableHeight = HinooTypography.baselineCanvasHeight -
        HinooTypography.verticalPadding(
              HinooTypography.baselineCanvasWidth,
            ) *
            2;
    const maximumTextHeight = HinooTypography.maxLines *
        HinooTypography.fontSize *
        HinooTypography.lineHeight;

    expect(maximumTextHeight, lessThanOrEqualTo(availableHeight));
  });

  testWidgets(
      'historical Hinoo text starts at 18 and scales down only to stay visible',
      (tester) async {
    final legacyText = List.generate(
      21,
      (index) => 'Riga storica ${index + 1} con testo completo',
    ).join('\n');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: HinooSlideView(
              slide: HinooSlide(
                backgroundImage: null,
                text: legacyText,
                isTextWhite: true,
              ),
              width: HinooTypography.baselineCanvasWidth,
              height: HinooTypography.baselineCanvasHeight,
              gap: 0,
              gapColor: Colors.black,
              scaleLegacyTextToFit: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final fittedFinder =
        find.byKey(const ValueKey('hinoo-legacy-fitted-text'));
    final textFinder = find.descendant(
      of: fittedFinder,
      matching: find.byType(Text),
    );
    final fittedBox = tester.renderObject<RenderBox>(fittedFinder);
    final textBox = tester.renderObject<RenderBox>(textFinder);
    final transformedTextBounds = MatrixUtils.transformRect(
      textBox.getTransformTo(fittedBox),
      Offset.zero & textBox.size,
    );
    final renderedText = tester.widget<Text>(textFinder);

    expect(renderedText.style?.fontSize, HinooTypography.fontSize);
    expect(renderedText.softWrap, isFalse);
    expect(transformedTextBounds.left, greaterThanOrEqualTo(0));
    expect(transformedTextBounds.top, greaterThanOrEqualTo(0));
    expect(
        transformedTextBounds.right, lessThanOrEqualTo(fittedBox.size.width));
    expect(
      transformedTextBounds.bottom,
      lessThanOrEqualTo(fittedBox.size.height),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved editor text keeps its original size and manual line breaks',
      (tester) async {
    const editorText = 'Prima riga\nSeconda riga\nTerza riga';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: HinooSlideView(
              slide: HinooSlide(
                backgroundImage: null,
                text: editorText,
                isTextWhite: true,
              ),
              width: HinooTypography.baselineCanvasWidth,
              height: HinooTypography.baselineCanvasHeight,
              gap: 0,
              gapColor: Colors.black,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final textFinder = find.text(editorText);
    final renderedText = tester.widget<Text>(textFinder);

    expect(renderedText.data, editorText);
    expect(renderedText.style?.fontSize, HinooTypography.fontSize);
    expect(
      renderedText.style?.fontWeight,
      HinooTypography.textStyle(color: Colors.white).fontWeight,
    );
    expect(renderedText.softWrap, isFalse);
    expect(find.byType(FittedBox), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
