import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CenteringMultilineField extends StatefulWidget {
  const CenteringMultilineField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.style,
    this.horizontalPadding = EdgeInsets.zero,
    this.maxLines,
    this.minLines,
    this.decoration,
    this.onChanged,
    this.inputFormatters,
    this.keyboardType = TextInputType.multiline,
    this.textInputAction = TextInputAction.newline,
    this.autofocus = false,
    this.readOnly = false,
    this.expands = true,
    this.scrollPhysics,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.autofillHints,
    this.enabled,
    this.hardConstraints,
    this.onEditingComplete,
    this.onSubmitted,
    this.cursorColor,
    this.cursorWidth,
    this.cursorRadius,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextStyle style;
  final EdgeInsets horizontalPadding;
  final int? maxLines;
  final int? minLines;
  final InputDecoration? decoration;
  final VoidCallback? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool autofocus;
  final bool readOnly;
  final bool expands;
  final ScrollPhysics? scrollPhysics;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final bool enableSuggestions;
  final Iterable<String>? autofillHints;
  final bool? enabled;
  final BoxConstraints? hardConstraints;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final Color? cursorColor;
  final double? cursorWidth;
  final Radius? cursorRadius;

  @override
  State<CenteringMultilineField> createState() =>
      _CenteringMultilineFieldState();
}

class _CenteringMultilineFieldState extends State<CenteringMultilineField> {
  final ScrollController _scrollController = ScrollController();
  double? _lastPadTop;
  bool _pendingScroll = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChange);
  }

  @override
  void didUpdateWidget(CenteringMultilineField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChange);
      widget.controller.addListener(_handleControllerChange);
      _pendingScroll = true;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChange);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    widget.onChanged?.call();
    if (mounted) {
      setState(() {
        _pendingScroll = true;
      });
    } else {
      _pendingScroll = true;
    }
  }

  void _scheduleScroll(double padTop) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      if (padTop > 0) {
        if (_scrollController.position.pixels != 0) {
          _scrollController.jumpTo(0);
        }
      } else {
        final double maxExtent = _scrollController.position.maxScrollExtent;
        if ((_scrollController.position.pixels - maxExtent).abs() > 0.5) {
          _scrollController.jumpTo(maxExtent);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget field = LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 0;
        final double maxHeight =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 0;

        final String textForLayout =
            widget.controller.text.isEmpty ? ' ' : widget.controller.text;
        // Layout with very large width to prevent automatic wrapping
        // Input formatters will enforce actual line width limits
        final double layoutWidth = maxWidth * 10; // Much larger than screen
        final TextPainter painter = TextPainter(
          text: TextSpan(text: textForLayout, style: widget.style),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          maxLines: widget.maxLines,
        )..layout(minWidth: 0, maxWidth: layoutWidth);

        double textHeight = painter.size.height;
        if (textHeight <= 0) {
          final double baseLineHeight =
              (widget.style.height ?? 1.0) * (widget.style.fontSize ?? 16);
          textHeight = baseLineHeight;
        }

        double padTop = 0;
        if (maxHeight.isFinite && maxHeight > 0) {
          padTop = math.max(0, (maxHeight - textHeight) / 2);
        }

        final bool shouldAdjust = _pendingScroll ||
            _lastPadTop == null ||
            (padTop - _lastPadTop!).abs() > 0.5;
        if (shouldAdjust) {
          _scheduleScroll(padTop);
          _pendingScroll = false;
          _lastPadTop = padTop;
        }

        final InputDecoration baseDecoration =
            widget.decoration ?? const InputDecoration();
        final EdgeInsets contentPadding = EdgeInsets.only(
          top: padTop,
          left: widget.horizontalPadding.left,
          right: widget.horizontalPadding.right,
          bottom: widget.horizontalPadding.bottom,
        );

        final InputDecoration effectiveDecoration = baseDecoration.copyWith(
          isDense: true,
          contentPadding: contentPadding,
        );

        final bool expands = widget.expands;
        final int? effectiveMaxLines = expands ? null : widget.maxLines;
        final int? effectiveMinLines = expands ? null : widget.minLines;

        // Wrap TextField in OverflowBox to give it more internal width
        // This prevents automatic text wrapping at the container edge
        return OverflowBox(
          alignment: Alignment.center,
          maxWidth: maxWidth * 3, // Give 3x width to prevent wrapping
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            style: widget.style,
            cursorColor: widget.cursorColor,
            cursorWidth: widget.cursorWidth ?? 2,
            cursorRadius: widget.cursorRadius,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            textCapitalization: widget.textCapitalization,
            autocorrect: widget.autocorrect,
            enableSuggestions: widget.enableSuggestions,
            autofocus: widget.autofocus,
            readOnly: widget.readOnly,
            enabled: widget.enabled,
            expands: expands,
            minLines: effectiveMinLines,
            maxLines: effectiveMaxLines,
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.top,
            inputFormatters: widget.inputFormatters,
            scrollController: _scrollController,
            scrollPhysics: widget.scrollPhysics ?? const ClampingScrollPhysics(),
            decoration: effectiveDecoration,
            onEditingComplete: widget.onEditingComplete,
            onSubmitted: widget.onSubmitted,
            autofillHints: widget.autofillHints,
          ),
        );
      },
    );

    if (widget.hardConstraints != null) {
      field =
          ConstrainedBox(constraints: widget.hardConstraints!, child: field);
    }

    return field;
  }
}
