import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Widgets/honoo_standard_page.dart';
import 'package:honoo/Widgets/section_text.dart';

class LaBandaPage extends StatelessWidget {
  const LaBandaPage({super.key});

  static const String laBandaText =
      'La Banda\n\n'
      'Immagina un gruppo\n'
      'formato da persone\n'
      'che condividono\n'
      'fiducia e stima\n'
      'reciproca\n'
      'e tre convinzioni\n\n'
      'La prima convinzione è che\n'
      'esprimere la propria creatività\n'
      'attraverso la realizzazione\n'
      'di opere\n'
      'renda la vita più felice\n\n'
      'La seconda convinzione\n'
      'consiste nell’essere d’accordo\n'
      'sull’importanza\n'
      'di impegnarsi ogni giorno,\n'
      'per esprimere la propria creatività\n\n'
      'La terza convinzione\n'
      'è che la creatività\n'
      'e l’impegno quotidiano\n'
      'traggano beneficio\n'
      'da Incontri periodici,\n'
      'in cui il cuore sia la creatività,\n'
      'e dove vengano rispettate\n'
      'tre regole\n\n'
      'Sono regole semplici\n\n'
      'Ma cambiano\n'
      'completamente\n'
      'il modo di ascoltarsi\n\n'
      'Prima regola:\n'
      'parlano tutti,\n'
      'a turno\n\n'
      'Seconda regola:\n'
      'non si può interrompere nessuno,\n'
      'per nessun motivo\n\n'
      'Terza regola:\n'
      'non si può commentare\n'
      'quello che ha detto\n'
      'o letto un altro\n\n'
      'In ogni Incontro\n'
      'c’è qualcuno\n'
      'che ha il compito\n'
      'di assicurarsi\n'
      'che queste tre regole\n'
      'vengano rispettate\n\n';

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
      child: SectionText(
        key: const Key('section_text'),
        text: laBandaText,
        style: bodyStyle,
      ),
    );
  }
}
