import 'package:flutter/material.dart';

const String kHinooReferenceLine = '— Hai il presente. Non ti basta?';

double calibrateFontSizeForWidth({
  required TextStyle baseStyle,
  required double maxWidth,
  double targetFillRatio = 0.975,
  double minFactor = 0.6,
  double maxFactor = 2.4,
  String referenceLine = kHinooReferenceLine,
}) {
  final double baseSize = baseStyle.fontSize ?? 16.0;
  if (!maxWidth.isFinite || maxWidth <= 0 || referenceLine.trim().isEmpty) {
    return baseSize;
  }

  double clampSize(double value) {
    final double minSize = baseSize * minFactor;
    final double maxSize = baseSize * maxFactor;
    return value.clamp(minSize, maxSize);
  }

  TextPainter buildPainter(TextStyle style) => TextPainter(
        text: TextSpan(text: referenceLine, style: style),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(minWidth: 0, maxWidth: maxWidth);

  double widthForSize(double size) {
    final TextStyle style = baseStyle.copyWith(fontSize: size);
    return buildPainter(style).size.width;
  }

  final double targetWidth = maxWidth * targetFillRatio;

  double low = baseSize * minFactor;
  double high = baseSize * maxFactor;
  double best = clampSize(baseSize);

  for (int i = 0; i < 22; i++) {
    final double mid = (low + high) / 2;
    final double measured = widthForSize(mid);
    if (measured <= targetWidth) {
      best = mid;
      low = mid;
    } else {
      high = mid;
    }
    if ((high - low).abs() < 0.05) break;
  }

  return clampSize(best);
}
