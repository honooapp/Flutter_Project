import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Utility/utility.dart';
import 'package:honoo/Widgets/honoo_standard_page.dart';
import 'coming_soon_page.dart';

class LibriPage extends StatelessWidget {
  const LibriPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle style = GoogleFonts.arvo(
      color: HonooColor.onBackground,
      fontSize: 18,
      fontWeight: FontWeight.w200,
      height: 1.3,
    );

    final String full = Utility().libriText;
    final String firstTitle = 'Isola delle Storie';
    final int idx = full.indexOf(firstTitle);
    final String intro = idx >= 0 ? full.substring(0, idx) : full;

    String _header(String text) => text.replaceAll('\n', ' ').trim();

    final spans = <InlineSpan>[
      TextSpan(text: intro, style: style),
      TextSpan(
        text: 'Isola delle Storie\n\n',
        style: style.copyWith(
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.w700,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ComingSoonPage(
                  header: _header('Isola delle Storie'),
                  quote: '',
                  bibliography: '',
                ),
              ),
            );
          },
      ),
      TextSpan(
        text: 'Isole delle Storie\n(con illustrazioni di Joel Folda)\n\n',
        style: style.copyWith(
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.w700,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ComingSoonPage(
                  header: _header(
                      'Isole delle Storie\n(con illustrazioni di Joel Folda)'),
                  quote: '',
                  bibliography: '',
                ),
              ),
            );
          },
      ),
      TextSpan(
        text: 'Immacolato\n\n',
        style: style.copyWith(
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.w700,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ComingSoonPage(
                  header: _header('Immacolato'),
                  quote: '',
                  bibliography: '',
                ),
              ),
            );
          },
      ),
      TextSpan(
        text: 'I limoni sono finiti\n\n',
        style: style.copyWith(
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.w700,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ComingSoonPage(
                  header: _header('I limoni sono finiti'),
                  quote: '',
                  bibliography: '',
                ),
              ),
            );
          },
      ),
      TextSpan(
        text: 'Almeno\navresti potuto\ncambiare i nomi\n\n',
        style: style.copyWith(
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.w700,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ComingSoonPage(
                  header: _header('Almeno\navresti potuto\ncambiare i nomi'),
                  quote: '',
                  bibliography: '',
                ),
              ),
            );
          },
      ),
      TextSpan(
        text: 'Papà,\nma tu mi vuoi bene?\n',
        style: style.copyWith(
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.w700,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ComingSoonPage(
                  header: _header('Papà,\nma tu mi vuoi bene?'),
                  quote: '',
                  bibliography: '',
                ),
              ),
            );
          },
      ),
    ];

    return HonooStandardPage(
      contentWidthFactor: 0.45,
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(children: spans),
      ),
    );
  }
}
