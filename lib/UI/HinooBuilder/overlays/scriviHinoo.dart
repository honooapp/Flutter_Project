import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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
              fontSize: 15,
              height: 1.3,
            );

            return ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.controller,
              builder: (context, value, _) {
                final int lineCount = _countLines(value.text, maxWidth, textStyle);
                final bool alignTop = lineCount > 1;

                return TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  textAlignVertical:
                      alignTop ? TextAlignVertical.top : TextAlignVertical.center,
                  expands: true,
                  minLines: null,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  scrollPhysics: const NeverScrollableScrollPhysics(),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  inputFormatters: [
                    _lineLimitFormatter(maxWidth, textStyle),
                  ],
                  style: textStyle,
                );
              },
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
    final painter = _createPainter(text, maxWidth, style);
    return painter.computeLineMetrics().length;
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
        final _ClipResult clip = _clipToMaxLines(newValue, maxWidth, style);
        if (clip.text == oldValue.text && clip.selection == null) {
          return oldValue;
        }
        return TextEditingValue(
          text: clip.text,
          selection: clip.selection ?? oldValue.selection,
          composing: TextRange.empty,
        );
      }

      return newValue;
    });
  }

  TextSelection _clampSelection(TextSelection selection, int maxLength) {
    final int base = selection.baseOffset.clamp(0, maxLength);
    final int extent = selection.extentOffset.clamp(0, maxLength);

    if (selection.isCollapsed) {
      return TextSelection.collapsed(
        offset: extent,
        affinity: selection.affinity,
      );
    }

    return TextSelection(
      baseOffset: base,
      extentOffset: extent,
      affinity: selection.affinity,
      isDirectional: selection.isDirectional,
    );
  }

  _ClipResult _clipToMaxLines(
    TextEditingValue candidate,
    double maxWidth,
    TextStyle style,
  ) {
    final String text = candidate.text;
    if (text.isEmpty) {
      return _ClipResult(text, null);
    }

    if (_countLines(text, maxWidth, style) <= _maxLines) {
      return _ClipResult(text, null);
    }

    int low = 0;
    int high = text.length;
    int best = 0;

    while (low <= high) {
      final int mid = (low + high) >> 1;
      final String probe = text.substring(0, mid);
      if (_countLines(probe, maxWidth, style) <= _maxLines) {
        best = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    final String clipped = text.substring(0, best);
    final TextSelection? selection = candidate.selection.isValid
        ? _clampSelection(candidate.selection, clipped.length)
        : null;
    return _ClipResult(clipped, selection);
  }
}

class _ClipResult {
  _ClipResult(this.text, this.selection);

  final String text;
  final TextSelection? selection;
}
