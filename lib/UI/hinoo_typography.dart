import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Fixed typography constants for Hinoo text.
/// Font size and line height do NOT scale with screen size.
class HinooTypography {
  /// Reference line that defines maximum line width at baseline screen size
  static const String referenceLine = '— Hai il presente. Non ti basta?';

  /// Fixed font size in dp/points (does not scale)
  static const double fontSize = 18.0;

  /// Fixed line height multiplier (approximately 1.35-1.4 from image analysis)
  static const double lineHeight = 1.375;

  /// Fixed horizontal padding per side
  static const double horizontalPadding = 32.0;

  /// Baseline canvas width for reference (360px = 9:16 aspect)
  static const double baselineCanvasWidth = 360.0;

  /// Vertical padding - can be proportional or fixed
  static const double verticalPaddingBase = 40.0;

  /// Maximum number of lines allowed
  static const int maxLines = 20;

  /// Aspect ratio for Hinoo canvas (9:16 like Instagram Story)
  static const double aspectRatio = 9 / 16;

  /// Export dimensions (PNG)
  static const double exportWidth = 1080.0;
  static const double exportHeight = 1920.0;

  /// Returns the base TextStyle for Hinoo text
  static TextStyle textStyle({required Color color, FontWeight? fontWeight}) {
    return GoogleFonts.lora(
      fontSize: fontSize,
      height: lineHeight,
      color: color,
      fontWeight: fontWeight ?? FontWeight.w400,
    );
  }

  /// Returns the base TextStyle for display/viewer (slightly bolder)
  static TextStyle displayTextStyle({required Color color}) {
    return textStyle(color: color, fontWeight: FontWeight.w600);
  }

  /// Calculate usable width after padding
  static double usableWidth(double canvasWidth) {
    return (canvasWidth - (horizontalPadding * 2)).clamp(1.0, double.infinity);
  }

  /// Calculate vertical padding (can scale slightly for very large/small screens)
  static double verticalPadding(double canvasWidth) {
    // Keep it mostly fixed, but allow some scaling for extreme sizes
    final scale = (canvasWidth / baselineCanvasWidth).clamp(0.8, 2.0);
    return verticalPaddingBase * scale;
  }

  /// Calculate canvas width from height maintaining aspect ratio
  static double canvasWidthFromHeight(double height) {
    if (!height.isFinite || height <= 0) return baselineCanvasWidth;
    return height * aspectRatio;
  }
}
