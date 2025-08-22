import 'package:flutter/material.dart';
import 'package:honoo/IsolaDelleStorie/Pages/IslandPage.dart';
import 'package:honoo/Pages/ComingSoonPage.dart';
import 'package:honoo/Pages/MoonPage.dart';
import 'package:honoo/Pages/NewHonooPage.dart';
import 'package:honoo/Utility/HonooColors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Controller/DeviceController.dart';
import '../Utility/Utility.dart';
import 'package:sizer/sizer.dart';

import 'ChestPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HonooColor.background,
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          // CONTENUTO PRINCIPALE
          Column(
            children: [
              Opacity(
                opacity: 0.5,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: SizedBox(
                    height: 50,
                    child: Center(
                      child: Text(
                        Utility().appName,
                        style: GoogleFonts.libreFranklin(
                          color: HonooColor.secondary,
                          fontSize: 30,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: 100.w,
                    child: Row(
                      children: [
                        Expanded(child: Container()),
                        Container(
                          constraints: DeviceController().isPhone()
                              ? BoxConstraints(maxWidth: 100.w)
                              : BoxConstraints(maxWidth: 50.w),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 80.h,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    // Testi centrali (scrollabili)
                                    Positioned.fill(
                                      top: 0,
                                      child: Align(
                                        alignment: Alignment.topCenter,
                                        child: SingleChildScrollView(
                                          child: Column(
                                            children: [
                                              Text(
                                                Utility().textHome1,
                                                style: GoogleFonts.arvo(
                                                  color: HonooColor.onBackground,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const Padding(
                                                  padding: EdgeInsets.all(10.0)),
                                              Text(
                                                Utility().textHome2,
                                                style: GoogleFonts.arvo(
                                                  color: HonooColor.onBackground,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(child: Container()),
                      ],
                    ),
                  ),
                ),
              ),

              // FOOTER con onde + icone, protetto da clamp anti-overflow
              SizedBox(
                height: 105,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;

                    // dimensioni icone (coerenti con prima)
                    const double chestSize = 70;   // scrigno
                    const double bottleSize = 70;  // bottiglia
                    const double islandSize = 180; // isola

                    // posizioni "storiche" rispetto al centro
                    final double chestCenterX = w / 2 - chestSize / 2;
                    final double islandTargetX = (w / 2) - 200;
                    final double bottleTargetX = (w / 2) + 80;

                    // clamp entro [0, w - size] per evitare tagli a dx/sx
                    final double islandX =
                    islandTargetX.clamp(0.0, (w - islandSize)).toDouble();
                    final double bottleX =
                    bottleTargetX.clamp(0.0, (w - bottleSize)).toDouble();
                    final double chestX =
                    chestCenterX.clamp(0.0, (w - chestSize)).toDouble();

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [


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

                        // 3) Isola e Scrigno DOPO (restano sopra le onde)
                        Positioned(
                          bottom: -16,
                          left: islandX,
                          child: IconButton(
                            icon: SvgPicture.asset(
                              "assets/icons/isoladellestorie/island.svg",
                              color: HonooColor.onBackground,
                              width: islandSize,
                              height: islandSize,
                              semanticsLabel: 'Island',
                            ),
                            iconSize: islandSize,
                            splashRadius: 1,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const IslandPage()),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          bottom: -20,
                          left: chestX,
                          child: IconButton(
                            icon: SvgPicture.asset(
                              "assets/icons/chest.svg",
                              semanticsLabel: 'Chest',
                            ),
                            iconSize: chestSize,
                            splashRadius: 40,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ChestPage()),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),

          // 🌙 LUNA FISSA IN ALTO A DESTRA (sempre visibile e cliccabile)
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: SvgPicture.asset(
                    "assets/icons/moon.svg",
                    semanticsLabel: 'Moon',
                  ),
                  iconSize: 60,
                  splashRadius: 32,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MoonPage(),
                        // builder: (context) => ComingSoonPage(
                        //   header: Utility().readMoonHeader,
                        //   quote: Utility().shakespeare,
                        //   bibliography: Utility().bibliography,
                        // ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
