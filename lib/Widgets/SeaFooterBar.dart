import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:honoo/Utility/HonooColors.dart';

// Pagine per la navigazione (come in HomePage)
import 'package:honoo/IsolaDelleStorie/Pages/IslandPage.dart';
import 'package:honoo/Pages/NewHonooPage.dart';
import 'package:honoo/Pages/ChestPage.dart';

/// Barra “mare” riutilizzabile con onde + isola (sx) + scrigno (centro) + bottiglia (dx)
/// Posizioni, dimensioni e z-order identici alla HomePage.
class SeaFooterBar extends StatelessWidget {
  const SeaFooterBar({super.key});

  /// Altezza fissa come in HomePage
  static const double height = 105;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;

          // Dimensioni icone (coerenti con HomePage)
          const double chestSize = 70;   // scrigno
          const double bottleSize = 70;  // bottiglia
          const double islandSize = 180; // isola

          // Posizioni "storiche" rispetto al centro (coerenti con HomePage)
          final double chestCenterX  = w / 2 - chestSize / 2;
          final double islandTargetX = (w / 2) - 200;
          final double bottleTargetX = (w / 2) + 80;

          // Clamp per evitare tagli laterali
          final double islandX = islandTargetX.clamp(0.0, (w - islandSize)).toDouble();
          final double bottleX = bottleTargetX.clamp(0.0, (w - bottleSize)).toDouble();
          final double chestX  = chestCenterX.clamp(0.0, (w - chestSize)).toDouble();

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Onde (non bloccano i tap)
              // 2) Onde in MEZZO (sopra la bottiglia) ma non bloccano i tap
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: SizedBox(
                    height: 10,
                    child: Container(color: HonooColor.wave1),
                  ),
                ),
              ),

              // 1) Bottiglia PRIMA (così è sotto graficamente)
              Positioned(
                bottom: 10,
                left: bottleX,
              child: IconButton(
                icon: SvgPicture.asset(
                  "assets/icons/bottle.svg",
                  semanticsLabel: 'Bottle',
                ),
                iconSize: bottleSize,
                splashRadius: 40,
                tooltip: 'Scrivi',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const NewHonooPage()),
                    );
                  },
                ),
              ),

              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: SizedBox(
                    height: 20,
                    child: Container(color: HonooColor.wave2),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: SizedBox(
                    height: 30,
                    child: Container(color: HonooColor.wave3),
                  ),
                ),
              ),

              // Isola (sx)
              Positioned(
                bottom: -16,
                left: islandX,
              child: IconButton(
                icon: SvgPicture.asset(
                  "assets/icons/isoladellestorie/island.svg",
                  colorFilter: const ColorFilter.mode(
                    HonooColor.onBackground,
                    BlendMode.srcIn,
                  ),
                  width: islandSize,
                  height: islandSize,
                  semanticsLabel: 'Island',
                ),
                iconSize: islandSize,
                splashRadius: 1,
                tooltip: "Vai all'Isola delle Storie",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const IslandPage()),
                  );
                  },
                ),
              ),

              // Scrigno (centro)
              Positioned(
                bottom: -20,
                left: chestX,
              child: IconButton(
                icon: SvgPicture.asset("assets/icons/chest.svg", semanticsLabel: 'Chest'),
                iconSize: chestSize,
                splashRadius: 40,
                tooltip: 'Apri il tuo Cuore',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ChestPage()),
                  );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
