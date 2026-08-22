import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Widgets/honoo_standard_page.dart';
import 'package:url_launcher/url_launcher.dart';

class RegiaAgentiPage extends StatelessWidget {
  const RegiaAgentiPage({super.key});

  static const String alessandroMolinaUrl =
      'https://www.linkedin.com/authwall?trk=gf&trkInfo=AQEKiDvNCY9k5wAAAZ_TKfSQOVjSt8GjBHYntEjt-HPxCMb7xQr32j-xeaqLUkZnvfqrUpn83qHvXKKKYHIKY1acgmDf7htNSAFpkUS9bOm7DEa8a16eUbCCpTlD4T-EdrqpifM=&original_referer=&sessionRedirect=https%3A%2F%2Fwww.linkedin.com%2Fin%2Falessandro-molina1%3Futm_source%3Dshare_via%26utm_content%3Dprofile%26utm_medium%3Dmember_ios';

  static const String _title = 'Regia degli Agenti\n\n';

  static const String _textBeforeAlessandro =
      '“Regia degli Agenti”\n'
      'non è una mia espressione,\n'
      'ma del mio amico\n';

  static const String _textAfterAlessandro =
      ',\n'
      'che è Capo Consigliere\n'
      'di honoo\n'
      'per tutto quello che riguarda\n'
      'le scelte informatiche\n\n'
      'Stiamo parlando\n'
      'di trasformare\n'
      'storie\n'
      'in siti,\n'
      'in videogiochi,\n'
      'in prodotti\n'
      'interattivi,\n'
      'guidando agenti AI\n'
      'come collaboratori\n'
      'tecnici\n\n'
      'Non stiamo parlando\n'
      'di vibe coding\n\n'
      'Stiamo parlando\n'
      'di Behavior Driven Design\n'
      'e di Gherkin,\n'
      'cioè\n'
      'di imparare\n'
      'a tessere scenari\n'
      'che una macchina\n'
      'possa comprendere,\n'
      'realizzare\n'
      'e verificare\n\n'
      'Sì,\n'
      'stiamo parlando\n'
      'di un nuovo modo\n'
      'di scrivere\n'
      'prodotti digitali\n\n'
      'Una storia\n'
      'non è una linea\n\n'
      'È un tessuto\n\n'
      'Ogni personaggio\n'
      'è un filo\n\n'
      'Ogni scelta\n'
      'intreccia\n'
      'altri fili\n\n'
      'Ogni prodotto\n'
      'digitale\n'
      'è una tessitura\n'
      'di comportamenti\n\n'
      'E dirigere\n'
      'gli agenti\n'
      'significa\n'
      'imparare\n'
      'a tessere\n\n';

  static const String regiaAgentiText =
      '$_title${_textBeforeAlessandro}Alessandro Molina$_textAfterAlessandro';

  @override
  Widget build(BuildContext context) {
    final TextStyle bodyStyle = GoogleFonts.arvo(
      color: HonooColor.onBackground,
      fontSize: 18,
      fontWeight: FontWeight.w200,
      height: 1.3,
    );

    return HonooStandardPage(
      contentWidthFactor: 0.45,
      child: Text.rich(
        TextSpan(
          style: bodyStyle,
          children: [
            TextSpan(
              text: _title,
              style: bodyStyle.copyWith(fontWeight: FontWeight.w700),
            ),
            const TextSpan(text: _textBeforeAlessandro),
            TextSpan(
              text: 'Alessandro Molina',
              style: bodyStyle.copyWith(
                decoration: TextDecoration.underline,
                decorationColor: bodyStyle.color,
                decorationThickness: 3,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  await launchUrl(
                    Uri.parse(alessandroMolinaUrl),
                    mode: LaunchMode.externalApplication,
                  );
                },
            ),
            const TextSpan(text: _textAfterAlessandro),
          ],
        ),
        key: const Key('section_text'),
        textAlign: TextAlign.center,
      ),
    );
  }
}
