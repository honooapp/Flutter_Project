import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:honoo/Widgets/width_limited_multiline_field.dart';
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
            const double horizontalPad = HinooTypography.horizontalPadding;
            final double verticalPad = HinooTypography.verticalPadding(canvasWidth);
            final TextStyle effectiveStyle = HinooTypography.textStyle(
              color: widget.textColor,
            );

            return Padding(
              padding: EdgeInsets.fromLTRB(
                  horizontalPad, verticalPad, horizontalPad, verticalPad),
              child: WidthLimitedMultilineField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                style: effectiveStyle,
                maxLines: HinooTypography.maxLines,
                maxCharsPerLine: HinooTypography.maxCharsPerLine,
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
              ),
            );
          },
        ),
      ),
    );
  }
}
