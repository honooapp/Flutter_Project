import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum InlineTextStyle { italic, bold }

/// Compact inline formatting stored inside the existing text field.
///
/// Private-use toggle characters keep the Supabase schema backwards
/// compatible while remaining invisible in editors and rendered content.
abstract final class InlineTextFormatting {
  static const String italicMarker = '\uE000';
  static const String boldMarker = '\uE001';

  static bool isMarker(String character) =>
      character == italicMarker || character == boldMarker;

  static String visibleText(String text) =>
      text.replaceAll(italicMarker, '').replaceAll(boldMarker, '');

  static int visibleLength(String text) => visibleText(text).characters.length;

  static bool hasVisibleText(String text) =>
      visibleText(text).trim().isNotEmpty;

  static TextEditingValue toggle(
    TextEditingValue value,
    InlineTextStyle style,
  ) {
    final selection = value.selection;
    if (!selection.isValid || selection.isCollapsed) return value;

    final marker = switch (style) {
      InlineTextStyle.italic => italicMarker,
      InlineTextStyle.bold => boldMarker,
    };
    final start = selection.start;
    final end = selection.end;
    final text = value.text;

    if (start > 0 &&
        end < text.length &&
        text.substring(start - 1, start) == marker &&
        text.substring(end, end + 1) == marker) {
      final updated = text
          .replaceRange(end, end + 1, '')
          .replaceRange(start - 1, start, '');
      return value.copyWith(
        text: updated,
        selection: TextSelection(baseOffset: start - 1, extentOffset: end - 1),
        composing: TextRange.empty,
      );
    }

    final updated = text
        .replaceRange(end, end, marker)
        .replaceRange(start, start, marker);
    return value.copyWith(
      text: updated,
      selection: TextSelection(baseOffset: start + 1, extentOffset: end + 1),
      composing: TextRange.empty,
    );
  }

  static List<InlineSpan> spans(
    String text, {
    required TextStyle style,
    bool preserveMarkers = false,
  }) {
    final spans = <InlineSpan>[];
    var italic = false;
    var bold = false;
    final buffer = StringBuffer();

    void flush() {
      if (buffer.isEmpty) return;
      spans.add(
        TextSpan(
          text: buffer.toString(),
          style: style.copyWith(
            fontStyle: italic ? FontStyle.italic : style.fontStyle,
            fontWeight: bold ? FontWeight.bold : style.fontWeight,
          ),
        ),
      );
      buffer.clear();
    }

    for (final character in text.characters) {
      if (isMarker(character)) {
        flush();
        if (preserveMarkers) {
          spans.add(
            TextSpan(
              text: character,
              style: style.copyWith(fontSize: 0.01, color: Colors.transparent),
            ),
          );
        }
        if (character == italicMarker) {
          italic = !italic;
        } else {
          bold = !bold;
        }
      } else {
        buffer.write(character);
      }
    }
    flush();
    return spans;
  }
}

class FormattedTextEditingController extends TextEditingController {
  FormattedTextEditingController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final effectiveStyle = style ?? const TextStyle();
    return TextSpan(
      style: effectiveStyle,
      children: InlineTextFormatting.spans(
        text,
        style: effectiveStyle,
        preserveMarkers: true,
      ),
    );
  }
}

class VisibleLengthLimitingTextInputFormatter extends TextInputFormatter {
  const VisibleLengthLimitingTextInputFormatter(this.maxLength);

  final int maxLength;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => InlineTextFormatting.visibleLength(newValue.text) <= maxLength
      ? newValue
      : oldValue;
}

/// Interpreta C e B inserite dalla tastiera virtuale come comandi di
/// formattazione quando sostituiscono una selezione non vuota.
class InlineFormattingShortcutTextInputFormatter extends TextInputFormatter {
  const InlineFormattingShortcutTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final selection = oldValue.selection;
    if (!selection.isValid || selection.isCollapsed) return newValue;

    final start = selection.start;
    final end = selection.end;
    if (start < 0 || end > oldValue.text.length) return newValue;

    final insertedLength =
        newValue.text.length - (oldValue.text.length - (end - start));
    if (insertedLength != 1) return newValue;

    final inserted = newValue.text.substring(start, start + 1);
    final style = switch (inserted.toLowerCase()) {
      'c' => InlineTextStyle.italic,
      'b' => InlineTextStyle.bold,
      _ => null,
    };
    if (style == null ||
        oldValue.text.replaceRange(start, end, inserted) != newValue.text) {
      return newValue;
    }

    return InlineTextFormatting.toggle(oldValue, style);
  }
}

class FormattedText extends StatelessWidget {
  const FormattedText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.softWrap = true,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;
  final bool softWrap;

  @override
  Widget build(BuildContext context) {
    if (!text.contains(InlineTextFormatting.italicMarker) &&
        !text.contains(InlineTextFormatting.boldMarker)) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
      );
    }
    return Text.rich(
      TextSpan(
        style: style,
        children: InlineTextFormatting.spans(text, style: style),
      ),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}
