import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'HonooColors.dart';

class FormattedText extends StatelessWidget {
  final String inputText;
  final Color color;
  final double fontSize;

  const FormattedText({required this.inputText, required this.color, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    const pattern = r'<(\w+)>(.*?)<\1>';
    final regex = RegExp(pattern);

    final List<InlineSpan> textSpans = [];

    inputText.splitMapJoin(
      regex,
      onMatch: (Match match) {
        final text = match.group(2);
        final tag = match.group(1);

        if (text != null && tag != null) {
          if (tag == 'b') {
            textSpans.add(TextSpan(text: text, style: GoogleFonts.arvo(color: color,fontSize: fontSize,fontWeight: FontWeight.w700,)));
          } else if (tag == 'i') {
            textSpans.add(TextSpan(text: text, style: GoogleFonts.arvo(color: color,fontSize: fontSize,fontWeight: FontWeight.w400,fontStyle: FontStyle.italic,)));
          } else if (tag == 'l') {
            final strings = text.split("||");
            textSpans.add(_buildHyperlinkSpan(strings[0], strings[1], context));
          }
        }

        return '';
      },
      onNonMatch: (String text) {
        textSpans.add(TextSpan(text: text, style: GoogleFonts.arvo(color: color,fontSize: fontSize,fontWeight: FontWeight.w400,)));
        return '';
      },
    );

    return RichText(text: TextSpan(children: textSpans), textAlign: TextAlign.center,);
  }

  TextSpan _buildHyperlinkSpan(String text, String link, BuildContext context) {
    return TextSpan(
      text: text,
      style: GoogleFonts.arvo(color: HonooColor.onBackground,fontSize: 18,fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
      recognizer: TapGestureRecognizer()
        ..onTap = () async {
          final Uri url = Uri.parse('https://$link');
          if (!await launchUrl(url)) {
                throw Exception('Could not launch $url');
          }
        },
    );
  }
}