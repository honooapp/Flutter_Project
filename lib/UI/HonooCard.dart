import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Entites/Honoo.dart';
import '../Utility/HonooColors.dart';

class HonooCard extends StatelessWidget {
  final Honoo honoo;

  const HonooCard({super.key, required this.honoo});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    Color cardBg;

    switch (honoo.type) {
      case HonooType.moon:
        cardBg = HonooColor.tertiary;
        break;
      case HonooType.answer:
        cardBg = HonooColor.secondary;
        break;
      case HonooType.personal:
        cardBg = HonooColor.background;
        break;
      default:
        cardBg = HonooColor.background;
    }


    return LayoutBuilder(
      builder: (context, constraints) {
        // Vincoli disponibili (live)
        final double availW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : media.size.width;

        final double rawH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : media.size.height;

        // Nessuna tastiera qui, ma rispettiamo le safe areas
        final double availH =
        (rawH - media.padding.vertical).clamp(0.0, double.infinity);

        if (availW <= 0 || availH <= 0) {
          return const SizedBox.shrink();
        }

        // Parametri layout (identici al builder)
        const double gap = 9.0;   // spazio tra box testo e immagine
        const double eps = 0.5;   // cuscinetto anti-rounding ridotto

        // Altezza totale = (image/2) + gap + image = 1.5*image + gap
        // Vincolo per altezza → image <= (availH - gap - eps) / 1.5
        final double maxByH = (availH - gap - eps) / 1.5;

        // Lato del quadrato immagine limitato da larghezza e altezza
        final double imageSize = math.min(availW, maxByH);

        // Dimensioni derivate (no floor → transizione fluida)
        final double textHeight = imageSize / 2;
        final double totalHeight = textHeight + gap + imageSize;

        return Center(
          child: Card(
            color: cardBg,
            elevation: 0,
            margin: EdgeInsets.zero,
            clipBehavior: Clip.none, // per coerenza con il builder
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            child: SizedBox(
              width: imageSize,     // larghezza blocco = lato del quadrato
              height: totalHeight,  // 1.5 × lato + gap
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ======== SEZIONE TESTO (stesso look del builder) ========
                  SizedBox(
                    width: imageSize,
                    height: textHeight,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: HonooColor.tertiary,
                        border: Border.all(color: Colors.black12),
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          honoo.text ?? '',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.libreFranklin(
                            color: HonooColor.onTertiary,
                            fontSize: 18,
                            height: 1.4,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 5, // come nel builder (limite logico)
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: gap),

                  // ======== SEZIONE IMMAGINE (quadrata) ========
                  SizedBox(
                    width: imageSize,
                    height: imageSize,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: HonooColor.tertiary,
                          image: (honoo.image != null && honoo.image.toString().isNotEmpty)
                              ? DecorationImage(
                            image: NetworkImage(honoo.image),
                            fit: BoxFit.cover,
                          )
                              : null,
                        ),
                        child: (honoo.image == null || honoo.image.toString().isEmpty)
                            ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Carica qui la tua immagine',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.libreFranklin(
                                color: HonooColor.onSecondary,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 22),
                            const Icon(
                              Icons.photo,
                              size: 48,
                              color: HonooColor.primary,
                            ),
                          ],
                        )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
