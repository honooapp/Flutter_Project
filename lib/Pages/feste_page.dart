import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Widgets/honoo_standard_page.dart';

class FestePage extends StatelessWidget {
  const FestePage({super.key});

  static const String festeText =
      "Una festa di honoo\n"
      "si svolge\n"
      "in uno spazio\n"
      "articolato\n"
      "in sette luoghi:\n\n"
      "la Vasca dei Messaggi,\n"
      "la Grotta del Poeta,\n"
      "l’Angolo del Fotografo,\n"
      "la Stanza del Grafico,\n"
      "il Tavolo del Nim,\n"
      "la Stanza Buia\n"
      "e l’Agorà.\n\n"
      "Ho molta voglia\n"
      "di raccontarti tutto\n"
      "nel dettaglio,\n"
      "ma ho deciso di resistere,\n"
      "per non rovinarti\n"
      "il gusto della sorpresa,\n"
      "quando sarai invitato\n"
      "alla tua prima\n"
      "festa di honoo.\n";

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
      child: Text(
        festeText,
        style: bodyStyle,
        textAlign: TextAlign.center,
      ),
    );
  }
}
