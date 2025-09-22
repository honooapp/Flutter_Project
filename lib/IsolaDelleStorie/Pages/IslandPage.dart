import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:honoo/IsolaDelleStorie/Controller/ExerciseController.dart';
import 'package:honoo/IsolaDelleStorie/Pages/ExercisePage.dart';
import 'package:honoo/IsolaDelleStorie/Utility/IsolaDelleStorieContentManager.dart';
import 'package:honoo/Utility/FormattedText.dart';
import 'package:honoo/Utility/HonooColors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../Controller/DeviceController.dart';
import 'package:sizer/sizer.dart';

import '../../Pages/ComingSoonPage.dart';
import '../../Pages/MoonPage.dart';
import '../../Pages/NewHonooPage.dart';
import '../../Utility/Utility.dart';

class IslandPage extends StatefulWidget {
  const IslandPage({super.key});

  @override
  State<IslandPage> createState() => _IslandPageState();
}

class _IslandPageState extends State<IslandPage> {
  bool infoVisible = false;

  @override
  Widget build(BuildContext context) {
    final Positioned info = Positioned(
      top: 0,
      left: 10.w,
      right: 10.w,
      height: 80.h,
      child: Stack(
        children: [
          Visibility(
            visible: infoVisible,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 80.w,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: FormattedText(
                      inputText: IsolaDelleStoreContentManager.e_0_0,
                      color: HonooColor.onBackground,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Visibility(
              visible: infoVisible,
              child: IconButton(
                icon: const Icon(Icons.close),
                color: HonooColor.onBackground,
                iconSize: 40,
                onPressed: () {
                  setState(() {
                    infoVisible = !infoVisible;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: HonooColor.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              // Header titolo
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: SizedBox(
                  height: 60,
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

              // Contenuto
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Larghezza utile della colonna centrale: intera su phone, ~50% su desktop
                          final double columnMaxW = DeviceController().isPhone()
                              ? constraints.maxWidth
                              : math.min(constraints.maxWidth, constraints.maxWidth * 0.5);

                          return Row(
                            children: [
                              const Expanded(child: SizedBox()),
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: columnMaxW),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 5),
                                    SizedBox(
                                      height: 70,
                                      child: Align(
                                        alignment: Alignment.topCenter,
                                        child: IsolaDelleStoreContentManager.getRichText(
                                          IsolaDelleStoreContentManager.homeDescription,
                                        ),
                                      ),
                                    ),

                                    // ====== MAPPA RESPONSIVE + PIN SCALABILI ======
                                    // NOTE: imposta aspectRatio con il TUO viewBox (width/height)
                                    IslandMapWithPins(
                                      svgAsset: "assets/icons/isoladellestorie/islandmap.svg",
                                      aspectRatio: 1440 / 1024, // <--- METTI IL TUO (viewBoxW / viewBoxH)
                                      // width: prende tutta la larghezza disponibile della colonna
                                      // (nessun 95.w fisso: ora scala davvero col contenitore)
                                      pins: const [
                                        // Sostituisci con le TUE percentuali reali (0..1)
                                        MapPinPct(
                                          xPct: 0.11, yPct: 0.62,
                                          asset: "assets/icons/isoladellestorie/button3.svg",
                                          index: 3,
                                        ),
                                        MapPinPct(
                                          xPct: 0.33, yPct: 0.70,
                                          asset: "assets/icons/isoladellestorie/button2.svg",
                                          index: 2,
                                        ),
                                        MapPinPct(
                                          xPct: 0.50, yPct: 0.97,
                                          asset: "assets/icons/isoladellestorie/button1.svg",
                                          index: 1,
                                        ),
                                        MapPinPct(
                                          xPct: 0.47, yPct: 0.40,
                                          asset: "assets/icons/isoladellestorie/button4.svg",
                                          index: 4,
                                        ),
                                        MapPinPct(
                                          xPct: 0.70, yPct: 0.38,
                                          asset: "assets/icons/isoladellestorie/button5.svg",
                                          index: 5,
                                        ),
                                        MapPinPct(
                                          xPct: 0.71, yPct: 0.52,
                                          asset: "assets/icons/isoladellestorie/button6.svg",
                                          index: 6,
                                        ),
                                        MapPinPct(
                                          xPct: 0.74, yPct: 0.68,
                                          asset: "assets/icons/isoladellestorie/button7.svg",
                                          index: 7,
                                        ),
                                        MapPinPct(
                                          xPct: 0.78, yPct: 0.86,
                                          asset: "assets/icons/isoladellestorie/button8.svg",
                                          index: 8,
                                        ),
                                        MapPinPct(
                                          xPct: 0.50, yPct: 1.00,
                                          asset: "assets/icons/isoladellestorie/button9.svg",
                                          index: 9,
                                        ),
                                      ],
                                      pinSizeFactor: 0.045, // 4.5% della larghezza mappa (scala con la mappa)
                                      // debugGrid: true, // <-- attiva per allineare i pin visivamente
                                      onPinTap: (index) => _openExercise(index),
                                    ),
                                  ],
                                ),
                              ),
                              const Expanded(child: SizedBox()),
                            ],
                          );
                        },
                      ),
                    ),

                    // Overlay regole
                    info,
                  ],
                ),
              ),

              // Footer (onde + icone)
              SizedBox(
                height: 80,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double w = constraints.maxWidth;

                    const double bottleSize = 70;
                    const double chestSize = 70;
                    const double homeSize = 40;
                    const double logoSize = 70;


                    final double bottleTargetX = (w / 2) + 60;
                    final double chestCenterX = (w / 2) - (chestSize / 2);
                    final double homeTargetX = (w / 2) - 190;
                    final double logoTargetX = (w / 2) + 110;


                    double clampX(double x, double size) =>
                        x.clamp(0.0, (w - size)).toDouble();

                    final double bottleX = clampX(bottleTargetX, bottleSize);
                    final double chestX = clampX(chestCenterX, chestSize);
                    final double homeX = clampX(homeTargetX, homeSize);
                    final double logoX = clampX(logoTargetX, logoSize);


                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          bottom: 50,
                          left: 0,
                          right: 0,
                          child: SizedBox(height: 10, child: Container(color: HonooColor.wave1)),
                        ),
                        Positioned(
                          bottom: 10,
                          left: bottleX,
                          child: IconButton(
                            icon: SvgPicture.asset("assets/icons/bottle.svg", semanticsLabel: 'Bottle'),
                            iconSize: bottleSize,
                            splashRadius: 40,
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const NewHonooPage()));
                            },
                          ),
                        ),
                        Positioned(
                          bottom: 30,
                          left: 0,
                          right: 0,
                          child: IgnorePointer(child: SizedBox(height: 20, child: Container(color: HonooColor.wave2))),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: IgnorePointer(child: SizedBox(height: 30, child: Container(color: HonooColor.wave3))),
                        ),
                        Positioned(
                          bottom: 0,
                          left: homeX,
                          child: IconButton(
                            icon: SvgPicture.asset(
                              "assets/icons/home.svg",
                              colorFilter: const ColorFilter.mode(
                                HonooColor.onBackground,
                                BlendMode.srcIn,
                              ),                              width: homeSize,
                              height: homeSize,
                              semanticsLabel: 'Home',
                            ),
                            iconSize: homeSize,
                            splashRadius: 1,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        Positioned(
                          bottom: -20,
                          left: chestX,
                          child: IconButton(
                            icon: SvgPicture.asset("assets/icons/chest.svg", semanticsLabel: 'Chest'),
                            iconSize: chestSize,
                            splashRadius: 40,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ComingSoonPage(
                                    header: Utility().chestHeaderTemporary,
                                    quote: Utility().shakespeare,
                                    bibliography: Utility().bibliography,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          bottom: -15,
                          left: logoX,
                          child: IconButton(
                            icon: SvgPicture.asset("assets/icons/honoo_logo.svg", semanticsLabel: 'Logo'),
                            iconSize: logoSize,
                            splashRadius: 30,
                            onPressed: () => setState(() => infoVisible = !infoVisible),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),

          // 🌙 Luna fissa
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: SvgPicture.asset("assets/icons/moon.svg", semanticsLabel: 'Moon'),
                  iconSize: 60,
                  splashRadius: 32,
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const MoonPage()));
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openExercise(int n) {
    final controller = ExerciseController();
    late ExercisePage page;

    switch (n) {
      case 1:
        page = ExercisePage(exercise: controller.getExercise1());
        break;
      case 2:
        page = ExercisePage(exercise: controller.getExercise2());
        break;
      case 3:
        page = ExercisePage(exercise: controller.getExercise3());
        break;
      case 4:
        page = ExercisePage(exercise: controller.getExercise4());
        break;
      case 5:
        page = ExercisePage(exercise: controller.getExercise5());
        break;
      case 6:
        page = ExercisePage(exercise: controller.getExercise6());
        break;
      case 7:
        page = ExercisePage(exercise: controller.getExercise7());
        break;
      case 8:
        page = ExercisePage(exercise: controller.getExercise8());
        break;
      case 9:
        page = ExercisePage(exercise: controller.getExercise9());
        break;
      default:
        page = ExercisePage(exercise: controller.getExercise1());
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

}

/// ============================================================================
///  MAPPA RESPONSIVE CON PIN SCALABILI (percentuali)
/// ============================================================================

class MapPinPct {
  /// Coordinate percentuali nel sistema della mappa (0..1)
  final double xPct;
  final double yPct;
  final String asset;
  final int index; // per sapere quale esercizio aprire

  const MapPinPct({
    required this.xPct,
    required this.yPct,
    required this.asset,
    required this.index,
  });
}

class IslandMapWithPins extends StatelessWidget {
  const IslandMapWithPins({
    super.key,
    required this.svgAsset,
    required this.aspectRatio, // viewBoxWidth / viewBoxHeight
    required this.pins,
    this.pinSizeFactor = 0.08, // % della larghezza mappa
    this.onPinTap,
    this.debugGrid = false,
  });

  final String svgAsset;
  final double aspectRatio;         // es: 1440/1024 (DEVE combaciare col viewBox)
  final List<MapPinPct> pins;
  final double pinSizeFactor;       // es: 0.04 => 4% della larghezza mappa
  final void Function(int index)? onPinTap;
  final bool debugGrid;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        // Occupiamo TUTTA la larghezza disponibile del contenitore padre
        final double targetW = constraints.maxWidth;
        final double targetH = targetW / aspectRatio;

        // Pin che scalano con la mappa
        final double pinSize = (targetW * pinSizeFactor).clamp(24.0, 160.0);

        return SizedBox(
          width: targetW,
          height: targetH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Mappa SVG che riempie l'area con l'AR già corretto
              Positioned.fill(
                child: SvgPicture.asset(svgAsset, fit: BoxFit.fill),
              ),

              // (Opzionale) Griglia di debug per tarare le percentuali
              if (debugGrid) ..._buildDebugGrid(targetW, targetH),

              // Pin percentuali
              ...pins.map((p) {
                final left = (p.xPct * targetW) - (pinSize / 2);
                final top  = (p.yPct * targetH) - (pinSize / 2);
                return Positioned(
                  left: left,
                  top: top,
                  child: IconButton(
                    icon: SvgPicture.asset(p.asset, width: pinSize, height: pinSize),
                    iconSize: pinSize,
                    splashRadius: pinSize * 0.75,
                    onPressed: () => onPinTap?.call(p.index),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildDebugGrid(double w, double h) {
    final lines = <Widget>[];
    // verticali
    for (int i = 1; i < 10; i++) {
      final x = w * (i / 10);
      lines.add(Positioned(left: x, top: 0, bottom: 0,
          child: Container(width: 1, color: Colors.white.withOpacity(0.2))));
    }
    // orizzontali
    for (int j = 1; j < 10; j++) {
      final y = h * (j / 10);
      lines.add(Positioned(top: y, left: 0, right: 0,
          child: Container(height: 1, color: Colors.white.withOpacity(0.2))));
    }
    return lines;
  }
}
