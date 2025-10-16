import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:honoo/Widgets/centering_multiline_field.dart';
import 'package:honoo/UI/hinoo_typography.dart';

class ScriviHinooOverlay extends StatefulWidget {
  const ScriviHinooOverlay({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.textColor,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final Color textColor;

  @override
  State<ScriviHinooOverlay> createState() => _ScriviHinooOverlayState();
}

class _ScriviHinooOverlayState extends State<ScriviHinooOverlay> {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Padding(
        padding: EdgeInsets.zero,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double canvasWidth = math.max(1, constraints.maxWidth);
            final double horizontalPad = HinooTypography.horizontalPadding;
            final double verticalPad = HinooTypography.verticalPadding(canvasWidth);
            final double usableWidth = HinooTypography.usableWidth(canvasWidth);
            final TextStyle effectiveStyle = HinooTypography.textStyle(
              color: widget.textColor,
            );

            return Padding(
              padding: EdgeInsets.fromLTRB(
                  horizontalPad, verticalPad, horizontalPad, verticalPad),
              child: CenteringMultilineField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                style: effectiveStyle,
                horizontalPadding: EdgeInsets.zero,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                autofocus: true,
                expands: true,
                scrollPhysics: const ClampingScrollPhysics(),
                cursorColor: Colors.white,
                cursorWidth: 3,
                cursorRadius: const Radius.circular(0),
                maxLines: null, // Allow multiple lines but no auto-wrapping per line
                inputFormatters: [
                  _lineWidthAndCountFormatter(usableWidth, effectiveStyle),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Measures the width of a line of text
  double _measureLineWidth(String line, TextStyle style) {
    if (line.isEmpty) return 0.0;
    
    final painter = TextPainter(
      text: TextSpan(text: line, style: style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    
    return painter.width;
  }

  /// Formatter that prevents lines from exceeding width and enforces max line count
  /// Uses two conditions: character count limit AND physical width limit
  TextInputFormatter _lineWidthAndCountFormatter(
    double maxWidth,
    TextStyle style,
  ) {
    // Maximum characters is based on the reference line length
    const int maxCharsPerLine = HinooTypography.referenceLine.length;
    
    return TextInputFormatter.withFunction((oldValue, newValue) {
      if (oldValue.text == newValue.text) {
        return newValue;
      }

      final bool isDeletion = newValue.text.length < oldValue.text.length;
      if (isDeletion) {
        return newValue;
      }

      // Check total line count first
      final lines = newValue.text.split('\n');
      if (lines.length > HinooTypography.maxLines) {
        return oldValue;
      }

      // Check each line: either too many characters OR too wide
      for (final line in lines) {
        // Condition 1: Line has more characters than reference line
        if (line.length > maxCharsPerLine) {
          return oldValue;
        }
        
        // Condition 2: Line width exceeds available space (for narrow screens)
        final lineWidth = _measureLineWidth(line, style);
        if (lineWidth > maxWidth) {
          return oldValue;
        }
      }

      return newValue;
    });
  }
}
