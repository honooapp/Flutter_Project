import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/UI/hinoo_typography.dart';

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
}
