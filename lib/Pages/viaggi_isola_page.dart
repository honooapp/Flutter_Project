import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/IsolaDelleStorie/Pages/campanelli_page.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Widgets/honoo_standard_page.dart';
import 'package:honoo/Widgets/section_text.dart';
// import 'package:honoo/Utility/responsive_layout.dart';

class ViaggiIsolaPage extends StatelessWidget {
  const ViaggiIsolaPage({super.key});

  static const String _textAboveMap =
      "Viaggi sull'Isola delle Storie\n\n"
      "Apri gli occhi,\n"
      "c’è l’Isola\n"
      "davanti a te\n\n"
      "Nessuna mappa\n"
      "può sostituire\n"
      "un viaggio,\n"
      "ma guardare\n"
      "una mappa\n"
      "può essere un modo\n"
      "di viaggiare\n\n"
      "Questa è la Mappa\n"
      "dell’Isola";

  static const String _textBelowMap =
      "Nella parte orientale\n"
      "ci sono i luoghi\n"
      "di un percorso\n"
      "di scrittura\n\n"
      "E nella parte occidentale\n"
      "non ci sono\n"
      "veramente\n"
      "i leoni\n\n"
      "Vuoi scoprire\n"
      "che c’è?\n\n";

  static const String _campanelliLinkText = "Vieni a vedere\n\n\n\n";

  @override
  Widget build(BuildContext context) {
    // Layout handled by HonooStandardPage; no local layoutMode needed

    final TextStyle bodyStyle = GoogleFonts.arvo(
      color: HonooColor.onBackground,
      fontSize: 18,
      fontWeight: FontWeight.w200,
      height: 1.3,
    );
    return HonooStandardPage(
      contentWidthFactor: 0.45,
      child: Column(
        key: const Key('section_text'),
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SectionText(text: _textAboveMap, style: bodyStyle),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: const AspectRatio(
                  aspectRatio: 7 / 5,
                  child: Image(
                    image: AssetImage(
                      "assets/icons/isoladellestorie/islandmap.jpeg",
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Text(_textBelowMap, style: bodyStyle, textAlign: TextAlign.center),
          InkWell(
            key: const Key('campanelli_link'),
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const CampanelliPage()),
                (route) => false,
              );
            },
            child: Text(
              _campanelliLinkText,
              style: bodyStyle.copyWith(
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
