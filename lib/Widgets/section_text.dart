import 'package:flutter/material.dart';

/// Testo informativo con il blocco iniziale, fino alla prima riga vuota,
/// evidenziato come titolo.
class SectionText extends StatelessWidget {
  const SectionText({
    required this.text,
    required this.style,
    this.textAlign = TextAlign.center,
    super.key,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final int titleEnd = text.indexOf('\n\n');
    assert(
      titleEnd >= 0,
      'SectionText richiede un titolo seguito da una riga vuota',
    );

    final int bodyStart = titleEnd < 0 ? text.length : titleEnd + 2;
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(
            text: text.substring(0, bodyStart),
            style: style.copyWith(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: text.substring(bodyStart)),
        ],
      ),
      textAlign: textAlign,
    );
  }
}
