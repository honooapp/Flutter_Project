import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Widgets/honoo_standard_page.dart';
import 'package:google_fonts/google_fonts.dart';

class VenceslaoPage extends StatelessWidget {
  const VenceslaoPage({super.key});

  static const String venceslaoCembaloText =
      "Sono nato a Napoli\n"
      "nel 1965.\n\n"
      "Ho vissuto in sei città\n"
      "e ho lavorato\n"
      "in contesti molto differenti.\n\n"
      "Se dovessi trovare\n"
      "un filo conduttore,\n"
      "credo che lo individuerei\n"
      "nella scrittura,\n\n"
      "che a volte\n"
      "ha assunto la forma\n"
      "dell’immagine,\n\n"
      "a volte\n"
      "della parola scritta,\n\n"
      "a volte\n"
      "della parola detta,\n\n"
      "a minori a rischio,\n"
      "a detenute,\n\n"
      "a studenti\n"
      "di scuole superiori,\n"
      "di Università,\n"
      "di Accademie di Belle Arti,\n\n"
      "a docenti.\n\n"
      "Per tredici anni\n"
      "ho scritto i testi\n"
      "di un programma televisivo\n"
      "per bambini,\n\n"
      "La Melevisione,\n\n"
      "e di tutto ciò\n"
      "che da quel programma\n"
      "è nato:\n\n"
      "canzoni,\n"
      "spettacoli,\n"
      "libri.\n\n"
      "Oggi\n"
      "insegno\n"
      "Teoria e metodo\n"
      "dei mass media\n"
      "all’Accademia di Belle Arti\n"
      "di Napoli.\n\n"
      "Scrivo.\n\n"
      "Alcuni testi\n"
      "sono in fase\n"
      "di pubblicazione,\n\n"
      "altri\n"
      "sono ancora\n"
      "in lavorazione.\n\n"
      "Papà,\n"
      "ma tu mi vuoi bene?\n\n"
      "è il romanzo\n"
      "a cui sto lavorando\n"
      "adesso.\n\n"
      "honoo\n"
      "nasce da tutto questo.\n\n\n";

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
        venceslaoCembaloText,
        style: bodyStyle,
        textAlign: TextAlign.center,
      ),
    );
  }
}
