import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A multiline text field that prevents automatic text wrapping by blocking input
/// when either character count or physical width limits are exceeded.
/// 
/// Users must manually insert line breaks (Enter key) to start new lines.
/// This ensures consistent typography across both Honoo and Hinoo.
class WidthLimitedMultilineField extends StatefulWidget {
  const WidthLimitedMultilineField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.style,
    required this.maxLines,
    required this.maxCharsPerLine,
    this.horizontalPadding = EdgeInsets.zero,
    this.minLines,
    this.decoration,
    this.onChanged,
    this.additionalInputFormatters,
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
  final int maxLines;
  final int maxCharsPerLine;
  final EdgeInsets horizontalPadding;
  final int? minLines;
  final InputDecoration? decoration;
  final VoidCallback? onChanged;
  final List<TextInputFormatter>? additionalInputFormatters;
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
  State<WidthLimitedMultilineField> createState() =>
      _WidthLimitedMultilineFieldState();
}

class _WidthLimitedMultilineFieldState extends State<WidthLimitedMultilineField> {
  final ScrollController _scrollController = ScrollController();
  double? _lastPadTop;
  bool _pendingScroll = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChange);
  }

  @override
  void didUpdateWidget(WidthLimitedMultilineField oldWidget) {
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

  /// Measures the width of a single line of text
  double _measureLineWidth(String line) {
    if (line.isEmpty) return 0.0;
    
    final painter = TextPainter(
      text: TextSpan(text: line, style: widget.style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    
    return painter.width;
  }

  /// Creates the input formatter that enforces both character and width limits
  TextInputFormatter _createWidthLimitFormatter(double maxWidth) {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      if (oldValue.text == newValue.text) return newValue;
      
      final bool isDeletion = newValue.text.length < oldValue.text.length;
      if (isDeletion) return newValue;
      
      // Check total line count (manual breaks only)
      final lines = newValue.text.split('\n');
      if (lines.length > widget.maxLines) {
        return oldValue;
      }
      
      // Check each line: prevent typing if EITHER condition is met:
      // 1. Line exceeds character limit
      // 2. Line exceeds physical width
      for (final line in lines) {
        if (line.length > widget.maxCharsPerLine) {
          return oldValue; // Block: too many characters
        }
        
        final lineWidth = _measureLineWidth(line);
        if (lineWidth > maxWidth) {
          return oldValue; // Block: line too wide
        }
      }
      
      return newValue;
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
        final double usableWidth = math.max(1, maxWidth - widget.horizontalPadding.horizontal);
        
        final TextPainter painter = TextPainter(
          text: TextSpan(text: textForLayout, style: widget.style),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          maxLines: widget.maxLines,
        )..layout(minWidth: 0, maxWidth: usableWidth);

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

        // Combine width limit formatter with any additional formatters
        final List<TextInputFormatter> allFormatters = [
          _createWidthLimitFormatter(usableWidth),
          ...?widget.additionalInputFormatters,
        ];

        return TextField(
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
          inputFormatters: allFormatters,
          scrollController: _scrollController,
          scrollPhysics: widget.scrollPhysics ?? const ClampingScrollPhysics(),
          decoration: effectiveDecoration,
          onEditingComplete: widget.onEditingComplete,
          onSubmitted: widget.onSubmitted,
          autofillHints: widget.autofillHints,
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
