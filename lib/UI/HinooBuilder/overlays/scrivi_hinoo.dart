import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:honoo/Widgets/width_limited_multiline_field.dart';
import 'package:honoo/UI/hinoo_typography.dart';
import 'package:honoo/Utility/typographic_substitutions_formatter.dart';

class ScriviHinooOverlay extends StatefulWidget {
  const ScriviHinooOverlay({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.textColor,
    this.hintText,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final Color textColor;
  final String? hintText;

  @override
  State<ScriviHinooOverlay> createState() => _ScriviHinooOverlayState();
}

class _ScriviHinooOverlayState extends State<ScriviHinooOverlay> {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double canvasWidth = math.max(1, constraints.maxWidth);

          final TextStyle effectiveStyle = HinooTypography.textStyle(
            color: widget.textColor,
          );

          return Padding(
            padding: HinooTypography.textViewportPadding(canvasWidth),
            child: WidthLimitedMultilineField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              style: effectiveStyle,
              maxLines: HinooTypography.maxLines,
              maxCharsPerLine: HinooTypography.maxCharsPerLine,
              preInputFormatters: const [TypographicSubstitutionsFormatter()],
              horizontalPadding: EdgeInsets.zero,
              scrollPadding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                hintText: widget.hintText,
                hintStyle: effectiveStyle.copyWith(
                  color: widget.textColor.withValues(alpha: 0.5),
                ),
              ),
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              autofocus: true,
              expands: true,
              scrollPhysics: const ClampingScrollPhysics(),
              cursorColor: Colors.white,
              cursorWidth: 3,
              cursorRadius: const Radius.circular(0),
            ),
          );
        },
      ),
    );
  }
}
