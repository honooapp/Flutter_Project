import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Widgets/ching/ching_scaffold.dart';

import '../IsolaDelleStorie/Entities/ching.dart';

class ChingPage extends StatelessWidget {
  const ChingPage({
    super.key,
    required this.entry,
  });

  final Ching entry;

  static const Color _red =
      Color(0xFF9E172F); // rosso stile screenshot (bordeaux)

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 10,
          offset: Offset(0, 6),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final numberHanziStyle = GoogleFonts.arvo(
      color: _red,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    );

    final titleStyle = GoogleFonts.arvo(
      color: _red,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    );

    return ChingScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        child: Column(
          children: [
            // CARD TESTO (numero dentro + hanzi + titolo)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  // "2. 坤"
                  Text(
                    '${entry.number}.',
                    style: numberHanziStyle,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    entry.hanzi,
                    style: numberHanziStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),

                  // Titolo (anche su 2 righe se serve)
                  Text(
                    entry.titleIt,
                    style: titleStyle,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // CARD IMMAGINE
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: _cardDecoration(),
              child: AspectRatio(
                aspectRatio: 1,
                child: SvgPicture.asset(
                  entry.assetPath,
                  colorFilter: const ColorFilter.mode(_red, BlendMode.srcIn),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
