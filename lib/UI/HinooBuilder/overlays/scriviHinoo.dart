import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Widgets/centering_multiline_field.dart';

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
  static const int _maxLines = 21;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double maxWidth = math.max(1, constraints.maxWidth);
            final textStyle = GoogleFonts.lora(
              color: widget.textColor,
              fontSize: 16,
              height: 1.3,
            );

            return CenteringMultilineField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              style: textStyle,
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
              inputFormatters: [
                _lineLimitFormatter(maxWidth, textStyle),
              ],
            );
          },
        ),
      ),
    );
  }

  TextPainter _createPainter(
    String text,
    double maxWidth,
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: null,
    )..layout(minWidth: 0, maxWidth: maxWidth);

    return painter;
  }

  int _countLines(
    String text,
    double maxWidth,
    TextStyle style,
  ) {
    if (text.isEmpty) return 0;
    final int manualCount = text.split('\n').length;
    final painter = _createPainter(text, maxWidth, style);
    final int autoCount = painter.computeLineMetrics().length;
    return math.max(autoCount, manualCount);
  }

  TextInputFormatter _lineLimitFormatter(
    double maxWidth,
    TextStyle style,
  ) {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      if (oldValue.text == newValue.text) {
        return newValue;
      }

      final bool isDeletion = newValue.text.length < oldValue.text.length;
      if (isDeletion) {
        return newValue;
      }

      final int newLineCount = _countLines(newValue.text, maxWidth, style);

      if (newLineCount > _maxLines) {
        return oldValue;
      }

      return newValue;
    });
  }
}
