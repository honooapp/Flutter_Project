import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'HonooColors.dart';

class FormattedText extends StatelessWidget {
  final String inputText;

  const FormattedText({required this.inputText});

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
            textSpans.add(TextSpan(text: text, style: GoogleFonts.arvo(color: HonooColor.onBackground,fontSize: 18,fontWeight: FontWeight.w700,)));
          } else if (tag == 'i') {
            textSpans.add(TextSpan(text: text, style: GoogleFonts.arvo(color: HonooColor.onBackground,fontSize: 18,fontWeight: FontWeight.w400,fontStyle: FontStyle.italic,)));
          } else if (tag == 'l') {
            textSpans.add(_buildHyperlinkSpan(text, context));
          }
        }

        return '';
      },
      onNonMatch: (String text) {
        textSpans.add(TextSpan(text: text, style: GoogleFonts.arvo(color: HonooColor.onBackground,fontSize: 18,fontWeight: FontWeight.w400,)));
        return '';
      },
    );

    return RichText(text: TextSpan(children: textSpans), textAlign: TextAlign.center,);
  }

  TextSpan _buildHyperlinkSpan(String text, BuildContext context) {
    return TextSpan(
      text: text,
      style: GoogleFonts.arvo(color: HonooColor.onBackground,fontSize: 18,fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
      recognizer: TapGestureRecognizer()
        ..onTap = () async {
          final Uri url = Uri.parse('https://$text');
          if (!await launchUrl(url)) {
                throw Exception('Could not launch $url');
          }
        },
    );
  }
}