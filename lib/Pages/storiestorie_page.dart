import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Widgets/honoo_standard_page.dart';
import 'package:url_launcher/url_launcher.dart';

class StoriestoriePage extends StatelessWidget {
  const StoriestoriePage({super.key});

  static final Uri siteUri = Uri.parse('http://storiestorie.it');

  static const String pageText =
      'storiestorie.it\n\n'
      'Parole\n\n'
      'Parole scritte\n\n'
      'Parole dette\n\n'
      'Parole lette\n\n'
      'Immagini\n\n'
      'Immagini raccontate\n\n'
      'La mia Stanza dei Giochi\n\n'
      'La mia Stanza della Memoria\n\n'
      'Uno spazio privato,\n'
      'da condividere\n'
      'con chi ne ha voglia\n\n'
      'Un laboratorio\n\n'
      'Il salotto\n'
      'che non ho\n'
      'a casa mia\n\n';

  @override
  Widget build(BuildContext context) {
    final TextStyle style = GoogleFonts.arvo(
      color: HonooColor.onBackground,
      fontSize: 18,
      fontWeight: FontWeight.w200,
      height: 1.3,
    );

    return HonooStandardPage(
      contentWidthFactor: 0.45,
      child: Text.rich(
        TextSpan(
          style: style,
          children: [
            TextSpan(
              text: 'storiestorie.it\n\n',
              style: style.copyWith(
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: style.color,
                decorationThickness: 3,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  await launchUrl(
                    siteUri,
                    mode: LaunchMode.externalApplication,
                  );
                },
            ),
            const TextSpan(
              text:
                  'Parole\n\n'
                  'Parole scritte\n\n'
                  'Parole dette\n\n'
                  'Parole lette\n\n'
                  'Immagini\n\n'
                  'Immagini raccontate\n\n'
                  'La mia Stanza dei Giochi\n\n'
                  'La mia Stanza della Memoria\n\n'
                  'Uno spazio privato,\n'
                  'da condividere\n'
                  'con chi ne ha voglia\n\n'
                  'Un laboratorio\n\n'
                  'Il salotto\n'
                  'che non ho\n'
                  'a casa mia\n\n',
            ),
          ],
        ),
        key: const Key('section_text'),
        textAlign: TextAlign.center,
      ),
    );
  }
}
