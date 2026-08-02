import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Widgets/honoo_standard_page.dart';

import 'home_page.dart';

class LunaPage extends StatelessWidget {
  const LunaPage({super.key});

  static const String lunaText =
      "Cosa c’è\n"
      "oggi\n"
      "sulla Luna?\n\n"
      "Qualcosa\n"
      "che ti incuriosisce?\n\n"
      "Ti basta guardare\n"
      "da lontano?\n\n"
      "O vorresti fare\n"
      "qualcosa di più?\n\n"
      "O molto di più?\n\n"
      "A lezione dico sempre\n"
      "che considero\n"
      "honoo e hinoo\n"
      "non come\n"
      "prodotti finiti,\n"
      "ma come momenti\n"
      "di un processo di scrittura,\n"
      "articolato\n"
      "come viaggio\n"
      "di esplorazione\n"
      "di un’Isola\n\n"
      "Però\n"
      "qui\n"
      "non sono\n"
      "a lezione\n\n"
      "E poi ci sono\n"
      "i momenti\n"
      "in cui esagero,\n"
      "come adesso,\n"
      "e allora dico\n"
      "che la Luna di honoo\n"
      "potrebbe essere\n"
      "l’app ideata,\n"
      "per gioco,\n"
      "da Dante\n"
      "o da Guido Cavalcanti,\n"
      "se l’incantesimo del Mago\n"
      "li avesse fatti riapparire\n"
      "dalle nostre parti,\n"
      "in questi giorni\n";

  @override
  Widget build(BuildContext context) {
    final TextStyle baseTextStyle = GoogleFonts.arvo(
      color: HonooColor.onBackground,
      fontSize: 18,
      fontWeight: FontWeight.w200,
      height: 1.3,
    );
    return HonooStandardPage(
      contentWidthFactor: 0.4,
      horizontalPadding: const EdgeInsets.symmetric(horizontal: 24.0),
      onHome: () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      },
      child: Text(lunaText, style: baseTextStyle, textAlign: TextAlign.center),
    );
  }
}
