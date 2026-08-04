import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Utility/typographic_substitutions_formatter.dart';

void main() {
  const formatter = TypographicSubstitutionsFormatter();

  TextEditingValue format(String oldText, String newText) {
    return formatter.formatEditUpdate(
      TextEditingValue(
        text: oldText,
        selection: TextSelection.collapsed(offset: oldText.length),
      ),
      TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      ),
    );
  }

  test('sostituisce le sequenze quando arriva uno spazio', () {
    expect(format('--', '-- ').text, '— ');
    expect(format('...', '... ').text, '… ');
    expect(format('<<', '<< ').text, '« ');
    expect(format('>>', '>> ').text, '» ');
  });

  test('sostituisce le sequenze quando arriva un Invio', () {
    expect(format('--', '--\n').text, '—\n');
    expect(format('...', '...\n').text, '…\n');
    expect(format('<<', '<<\n').text, '«\n');
    expect(format('>>', '>>\n').text, '»\n');
  });

  test('mantiene il cursore dopo il carattere di attivazione', () {
    final result = format('Test--', 'Test-- ');

    expect(result.text, 'Test— ');
    expect(result.selection, const TextSelection.collapsed(offset: 6));
  });

  test('non sostituisce sequenze incomplete o non ancora chiuse', () {
    expect(format('-', '--').text, '--');
    expect(format('..', '...').text, '...');
    expect(format('<', '<<').text, '<<');
    expect(format('>', '>>').text, '>>');
    expect(format('', '<<test').text, '<<test');
  });
}
