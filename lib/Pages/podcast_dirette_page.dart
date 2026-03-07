import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Utility/utility.dart';
import 'package:honoo/Widgets/honoo_standard_page.dart';

class PodcastDirettePage extends StatelessWidget {
  const PodcastDirettePage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle style = GoogleFonts.arvo(
      color: HonooColor.onBackground,
      fontSize: 18,
      fontWeight: FontWeight.w200,
      height: 1.3,
    );

    final List<InlineSpan> spans = [
      TextSpan(text: 'honoo\nsi ascolta\ne si guarda.\n\n', style: style),
      TextSpan(text: 'È voce.\nÈ immagine.\n\n', style: style),
      TextSpan(
        text: 'Un canale YouTube.\n',
        style: style.copyWith(
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _YouTubeInfoPage()),
            );
          },
      ),
      TextSpan(
        text: 'Un podcast.\n',
        style: style.copyWith(
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _PodcastInfoPage()),
            );
          },
      ),
      TextSpan(
        text: 'Un account Twitch.\n\n',
        style: style.copyWith(
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _TwitchInfoPage()),
            );
          },
      ),
      TextSpan(
          text:
              'Se vuoi,\npuoi ascoltare,\nguardare\ne partecipare.\n\n',
          style: style),
    ];

    return HonooStandardPage(
      contentWidthFactor: 0.45,
      child: RichText(textAlign: TextAlign.center, text: TextSpan(children: spans)),
    );
  }
}

class _YouTubeInfoPage extends StatelessWidget {
  const _YouTubeInfoPage();
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
      child: Text(
        Utility().podcastDiretteText,
        style: style,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _PodcastInfoPage extends StatelessWidget {
  const _PodcastInfoPage();
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
      child: Text(
        Utility().podcastDiretteText,
        style: style,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _TwitchInfoPage extends StatelessWidget {
  const _TwitchInfoPage();
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
      child: Text(
        Utility().podcastDiretteText,
        style: style,
        textAlign: TextAlign.center,
      ),
    );
  }
}

