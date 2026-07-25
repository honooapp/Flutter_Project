import 'package:flutter/services.dart';

/// Applies Honoo's typographic substitutions once a sequence is completed
/// with a space or a newline.
class HonooTypographicSubstitutionsFormatter extends TextInputFormatter {
  const HonooTypographicSubstitutionsFormatter();

  static const Map<String, String> _substitutions = {
    '...': '…',
    '--': '—',
    '<<': '«',
    '>>': '»',
  };

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (oldValue.text == newValue.text ||
        (newValue.composing.isValid && !newValue.composing.isCollapsed)) {
      return newValue;
    }

    final text = newValue.text;
    final output = StringBuffer();
    final offsetMap = List<int>.filled(text.length + 1, 0);
    var sourceOffset = 0;
    var changed = false;

    while (sourceOffset < text.length) {
      offsetMap[sourceOffset] = output.length;
      final match = _matchAt(text, sourceOffset);
      if (match != null) {
        final replacement = _substitutions[match]!;
        output.write(replacement);
        sourceOffset += match.length;
        for (
          var offset = sourceOffset - match.length + 1;
          offset <= sourceOffset;
          offset++
        ) {
          offsetMap[offset] = output.length;
        }
        changed = true;
        continue;
      }

      output.writeCharCode(text.codeUnitAt(sourceOffset));
      sourceOffset++;
      offsetMap[sourceOffset] = output.length;
    }

    if (!changed) return newValue;

    int mapOffset(int offset) => offsetMap[offset.clamp(0, text.length)];

    final selection = TextSelection(
      baseOffset: mapOffset(newValue.selection.baseOffset),
      extentOffset: mapOffset(newValue.selection.extentOffset),
      affinity: newValue.selection.affinity,
      isDirectional: newValue.selection.isDirectional,
    );
    final composing = newValue.composing.isValid
        ? TextRange(
            start: mapOffset(newValue.composing.start),
            end: mapOffset(newValue.composing.end),
          )
        : TextRange.empty;

    return newValue.copyWith(
      text: output.toString(),
      selection: selection,
      composing: composing,
    );
  }

  String? _matchAt(String text, int offset) {
    for (final sequence in _substitutions.keys) {
      final end = offset + sequence.length;
      if (end >= text.length ||
          !text.startsWith(sequence, offset) ||
          !_isTrigger(text.codeUnitAt(end))) {
        continue;
      }
      if (offset > 0 && text.codeUnitAt(offset - 1) == sequence.codeUnitAt(0)) {
        continue;
      }
      return sequence;
    }
    return null;
  }

  bool _isTrigger(int codeUnit) => codeUnit == 0x20 || codeUnit == 0x0A;
}
