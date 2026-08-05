import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Widgets/honoo_standard_page.dart';

class RegiaAgentiPage extends StatelessWidget {
  const RegiaAgentiPage({super.key});

  static const String regiaAgentiText =
      '“Regia degli Agenti”\n'
      'non è una mia espressione,\n'
      'ma del mio amico\n'
      'Alessandro Molina,\n'
      'che è Capo Consigliere\n'
      'di honoo\n'
      'per tutto quello che riguarda\n'
      'le scelte informatiche\n\n'
      'Stiamo parlando\n'
      'di trasformare\n'
      'storie\n'
      'in siti,\n'
      'in videogiochi,\n'
      'in prodotti interattivi,\n'
      'guidando agenti LLM\n'
      'come collaboratori tecnici\n\n'
      'Non stiamo parlando\n'
      'di vibe coding\n\n'
      'Stiamo parlando\n'
      'di Behavior Driven Design\n'
      'e di Gherkin,\n'
      'cioè\n'
      'di imparare\n'
      'a scrivere idee\n'
      'che una macchina\n'
      'possa comprendere,\n'
      'realizzare\n'
      'e verificare\n\n'
      'Sì,\n'
      'stiamo parlando\n'
      'di un nuovo modo\n'
      'di scrivere\n'
      'prodotti digitali\n';

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
        regiaAgentiText,
        key: const Key('regia_agenti_text'),
        style: bodyStyle,
        textAlign: TextAlign.center,
      ),
    );
  }
}
