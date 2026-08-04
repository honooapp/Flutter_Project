import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Widgets/honoo_standard_page.dart';
import 'package:honoo/Utility/honoo_colors.dart';

class PerformancePage extends StatelessWidget {
  const PerformancePage({super.key});

  static const String performanceText =
      "Venceslao Cembalo,\n"
      "Antonio Della Guardia\n"
      "e Sira Sebastianelli\n"
      "hanno presentato\n"
      "per la prima volta\n"
      "Isola delle Storie\n"
      "a Roma,\n"
      "nella Galleria\n"
      "Spazio Taverna\n\n"
      "Da Roma\n"
      "Isola delle Storie\n"
      "è arrivata\n"
      "Lunedì 13 maggio 2024,\n"
      "dalle 18.00 alle 21.00,\n"
      "alla Triennale di Milano,\n"
      "a Casa Lana,\n"
      "progettata da Ettore Sottsass\n\n"
      "Sì,\n"
      "honoo è stato invitato\n"
      "alla Triennale\n";

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
        performanceText,
        style: bodyStyle,
        textAlign: TextAlign.center,
      ),
    );
  }
}
