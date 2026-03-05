import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'honoo_colors.dart';

class FormattedText extends StatelessWidget {
  final String inputText;
  final Color color;
  final double fontSize;
  final FontWeight? fontWeight;

  const FormattedText(
      {super.key,
      required this.inputText,
      required this.color,
      required this.fontSize,
      this.fontWeight});

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
            textSpans.add(TextSpan(
                text: text,
                style: GoogleFonts.arvo(
                  color: color,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                )));
          } else if (tag == 'i') {
            textSpans.add(TextSpan(
                text: text,
                style: GoogleFonts.arvo(
                  color: color,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                )));
          } else if (tag == 'l') {
            final strings = text.split("||");
            textSpans.add(_buildHyperlinkSpan(strings[0], strings[1], context));
          } else if (tag == 'lb') {
            final strings = text.split("||");
            textSpans
                .add(_buildHyperlinkBoldSpan(strings[0], strings[1], context));
          }
        }

        return '';
      },
      onNonMatch: (String text) {
        // Auto-link raw URLs in non-tagged text
        final urlRegex = RegExp(r'(https?:\/\/[^\s]+)');
        int lastIndex = 0;
        for (final m in urlRegex.allMatches(text)) {
          if (m.start > lastIndex) {
            textSpans.add(TextSpan(
                text: text.substring(lastIndex, m.start),
                style: GoogleFonts.arvo(
                  color: color,
                  fontSize: fontSize,
                  fontWeight: fontWeight ?? FontWeight.w400,
                )));
          }
          final urlText = m.group(0)!;
          textSpans.add(_buildHyperlinkSpan(urlText, urlText, context));
          lastIndex = m.end;
        }
        if (lastIndex < text.length) {
          textSpans.add(TextSpan(
              text: text.substring(lastIndex),
              style: GoogleFonts.arvo(
                color: color,
                fontSize: fontSize,
                fontWeight: fontWeight ?? FontWeight.w400,
              )));
        }
        return '';
      },
    );

    return RichText(
      text: TextSpan(children: textSpans),
      textAlign: TextAlign.center,
    );
  }

  TextSpan _buildHyperlinkBoldSpan(
      String text, String link, BuildContext context) {
    final String href = link.startsWith('http') ? link : 'https://$link';
    return TextSpan(
      text: text,
      style: GoogleFonts.arvo(
        color: HonooColor.onBackground,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        decoration: TextDecoration.underline,
      ),
      recognizer: TapGestureRecognizer()
        ..onTap = () async {
          final Uri url = Uri.parse(href);
          if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
            throw Exception('Could not launch $url');
          }
        },
    );
  }

  TextSpan _buildHyperlinkSpan(String text, String link, BuildContext context) {
    final String href = link.startsWith('http') ? link : 'https://$link';
    return TextSpan(
      text: text,
      style: GoogleFonts.arvo(
          color: HonooColor.onBackground,
          fontSize: 18,
          fontWeight: fontWeight ?? FontWeight.w400,
          decoration: TextDecoration.underline),
      recognizer: TapGestureRecognizer()
        ..onTap = () async {
          final Uri url = Uri.parse(href);
          if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
            throw Exception('Could not launch $url');
          }
        },
    );
  }
}
