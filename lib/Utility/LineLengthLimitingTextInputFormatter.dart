import 'package:flutter/services.dart';

class LineLengthLimitingTextInputFormatter extends TextInputFormatter {
  final int maxLineLength;
  final int maxLines;

  LineLengthLimitingTextInputFormatter({
    required this.maxLineLength,
    required this.maxLines,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newLines = newValue.text.split('\n');
    final oldLines = oldValue.text.split('\n');
    final formattedLines = <String>[];
    var totalLines = 0;
    var limitation = false;

    if (newLines.length > maxLines) {
      // If the new value has more lines than the max allowed,
      // then keep the old value
      return oldValue;
    }

    for (final line in newLines) {
      if (line.length <= maxLineLength) {
        formattedLines.add(line);
      } else {
        formattedLines.add(oldLines[totalLines]);
        limitation = true;
      }
      totalLines++;
    }

    final formattedText = formattedLines.join('\n');
    final newTextValue = TextEditingValue(
      text: formattedText,
      selection: limitation ? oldValue.selection : newValue.selection,
    );

    return newTextValue;
  }
}
