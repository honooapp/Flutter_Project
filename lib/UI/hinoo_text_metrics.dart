import 'dart:math' as math;

class HinooTextMetrics {
  static const double _aspectRatio = 9 / 16;
  static const double _baselineCanvasWidth = 360.0;
  static const double _editingBaseFontSize = 16.0;
  static const double _displayBaseFontSize = 20.0;
  static const double _baseHorizontalPadding = 32.0;
  static const double _baseVerticalPadding = 40.0;

  static double _safeWidth(double width) =>
      width.isFinite && width > 0 ? width : _baselineCanvasWidth;

  static double _scale(double width) =>
      (_safeWidth(width) / _baselineCanvasWidth).clamp(0.75, 4.0);

  static double canvasWidthFromHeight(double height) {
    if (!height.isFinite || height <= 0) return _baselineCanvasWidth;
    return height * _aspectRatio;
  }

  static double editingFontSize(double canvasWidth) =>
      (_editingBaseFontSize * _scale(canvasWidth)).clamp(12.0, 34.0);

  static double editingHorizontalPadding(double canvasWidth) {
    final double scale = _scale(canvasWidth);
    final double padding = _baseHorizontalPadding * scale;
    final double maxPad = _safeWidth(canvasWidth) * 0.35;
    return padding.clamp(8.0, maxPad);
  }

  static double editingVerticalPadding(double canvasWidth) {
    final double scale = _scale(canvasWidth);
    return (_baseVerticalPadding * scale).clamp(24.0, 160.0);
  }

  static double displayFontSize(double canvasWidth) =>
      (_displayBaseFontSize * _scale(canvasWidth)).clamp(14.0, 72.0);

  static double displayHorizontalPadding(double canvasWidth) {
    final double scale = _scale(canvasWidth);
    final double padding = _baseHorizontalPadding * scale;
    final double maxPad = _safeWidth(canvasWidth) * 0.3;
    return padding.clamp(10.0, maxPad);
  }

  static double displayVerticalPadding(double canvasWidth) {
    final double scale = _scale(canvasWidth);
    return (_baseVerticalPadding * scale).clamp(32.0, 200.0);
  }

  static double editingTextAreaWidth(double canvasWidth) {
    final double width = _safeWidth(canvasWidth);
    final double horizontal = editingHorizontalPadding(width);
    return math.max(1, width - (horizontal * 2));
  }
}
