import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/IsolaDelleStorie/Controller/exercise_controller.dart';
import 'package:honoo/IsolaDelleStorie/Pages/exercise_page.dart';
import 'package:honoo/IsolaDelleStorie/Pages/full_island_page.dart';
import 'package:honoo/IsolaDelleStorie/Utility/isola_delle_storie_content_manager.dart';
import 'package:honoo/Utility/formatted_text.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Widgets/island_toolbar.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../Controller/device_controller.dart';
import 'package:sizer/sizer.dart';

import '../../Pages/moon_page.dart';
import '../../Pages/placeholder_page.dart';
import 'package:honoo/Widgets/honoo_app_title.dart';

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
                    color: HonooColor.wave1.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Builder(
                      builder: (context) {
                        const String firstMarker = 'in forme più complesse';
                        const String secondMarker = '<b>bianco<b> o <b>nero<b>';
                        final String full =
                            IsolaDelleStoreContentManager.withoutParagraphTrailingPeriods(
                              IsolaDelleStoreContentManager.e00,
                            );
                        final int firstMarkerIndex = full.indexOf(firstMarker);
                        final int secondMarkerIndex = full.indexOf(
                          secondMarker,
                          firstMarkerIndex < 0
                              ? 0
                              : firstMarkerIndex + firstMarker.length,
                        );

                        // Helper for responsive example images
                        Widget exampleImage({
                          required Key key,
                          required String assetPath,
                        }) => LayoutBuilder(
                          key: key,
                          builder: (ctx, constraints) {
                            final double maxW = constraints.maxWidth.isFinite
                                ? constraints.maxWidth
                                : MediaQuery.of(ctx).size.width;
                            final double width = math.min(maxW, 480.0);
                            return Center(
                              child: SizedBox(
                                width: width,
                                child: Image.asset(
                                  assetPath,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            );
                          },
                        );

                        if (firstMarkerIndex < 0 || secondMarkerIndex < 0) {
                          return FormattedText(
                            inputText: full,
                            color: HonooColor.onBackground,
                            fontSize: 18,
                          );
                        }

                        final int firstImageOffset =
                            firstMarkerIndex + firstMarker.length;
                        final int secondImageOffset =
                            secondMarkerIndex + secondMarker.length;

                        return Column(
                          key: const Key('island_info_content'),
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            FormattedText(
                              inputText: full.substring(0, firstImageOffset),
                              color: HonooColor.onBackground,
                              fontSize: 18,
                            ),
                            const SizedBox(height: 12),
                            exampleImage(
                              key: const Key('island_info_honoo_example'),
                              assetPath: 'assets/honooesempio.png',
                            ),
                            const SizedBox(height: 20),
                            FormattedText(
                              inputText: full.substring(
                                firstImageOffset,
                                secondImageOffset,
                              ),
                              color: HonooColor.onBackground,
                              fontSize: 18,
                            ),
                            const SizedBox(height: 12),
                            exampleImage(
                              key: const Key('island_info_hinoo_example'),
                              assetPath: 'assets/images/onboarding_hinoo.png',
                            ),
                            const SizedBox(height: 20),
                            FormattedText(
                              inputText: full.substring(secondImageOffset),
                              color: HonooColor.onBackground,
                              fontSize: 18,
                            ),
                          ],
                        );
                      },
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
                icon: SvgPicture.asset(
                  'assets/icons/cancella.svg',
                  width: 40,
                  height: 40,
                  colorFilter: const ColorFilter.mode(
                    HonooColor.onBackground,
                    BlendMode.srcIn,
                  ),
                ),
                iconSize: 40,
                tooltip: 'Chiudi',
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Column(
                children: [
                  // Header titolo
                  SizedBox(
                    height: 52,
                    child: Center(
                      child: HonooAppTitle(
                        onTap: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const PlaceholderPage(),
                            ),
                            (route) => false,
                          );
                        },
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
                              // Larghezza utile della colonna centrale: piena su phone, limite morbido su desktop.
                              final bool isPhone = DeviceController().isPhone();
                              const double desktopContentMaxWidth = 720;
                              final double columnMaxW = isPhone
                                  ? constraints.maxWidth
                                  : math.min(
                                      constraints.maxWidth,
                                      desktopContentMaxWidth,
                                    );

                              const double mapAspectRatio = 321 / 323;
                              const double mapHorizontalPadding =
                                  24.0; // 12 + 12
                              final double mapMaxHeight = _maxMapHeight(
                                context,
                              );
                              final double mapMaxWidthFromHeight =
                                  mapMaxHeight * mapAspectRatio;
                              final double mapAvailableWidth = math.max(
                                columnMaxW - mapHorizontalPadding,
                                0.0,
                              );
                              double targetMapWidth = mapAvailableWidth;
                              if (mapMaxWidthFromHeight > 0) {
                                targetMapWidth = targetMapWidth == 0
                                    ? mapMaxWidthFromHeight
                                    : math.min(
                                        targetMapWidth,
                                        mapMaxWidthFromHeight,
                                      );
                              }
                              if (targetMapWidth <= 0) {
                                targetMapWidth = mapMaxWidthFromHeight > 0
                                    ? mapMaxWidthFromHeight
                                    : (columnMaxW > 0
                                          ? columnMaxW - mapHorizontalPadding
                                          : 320.0);
                              }
                              final double targetMapHeight = math.min(
                                targetMapWidth / mapAspectRatio,
                                mapMaxHeight,
                              );

                              return Row(
                                children: [
                                  const Expanded(child: SizedBox()),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: columnMaxW,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(height: 5),
                                        SizedBox(
                                          height: 70,
                                          child: Align(
                                            alignment: Alignment.topCenter,
                                            child:
                                                IsolaDelleStoreContentManager.getRichText(
                                                  IsolaDelleStoreContentManager
                                                      .homeDescription,
                                                ),
                                          ),
                                        ),

                                        const SizedBox(height: 36),

                                        // Mappa SVG responsiva con pin proporzionali all'area visibile.
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12.0,
                                          ),
                                          child: Align(
                                            alignment: Alignment.center,
                                            child: SizedBox(
                                              width: targetMapWidth,
                                              height: targetMapHeight,
                                              child: IslandMapWithPins(
                                                svgAsset:
                                                    "assets/icons/isoladellestorie/islandmap.svg",
                                                aspectRatio: 321 / 323,
                                                pins: const [
                                                  // x/y: coordinate percentuali del luogo nel viewBox originale.
                                                  // dx/dy: offset percentuali per spostare il bottone accanto all'illustrazione.
                                                  MapPinModel(
                                                    id: 1,
                                                    x: 0.12,
                                                    y: 0.95,
                                                    dx: 0.00,
                                                    dy: 0.01,
                                                    assetSvg:
                                                        "assets/icons/isoladellestorie/button1.svg",
                                                    hint:
                                                        'Grotta delle Rondini',
                                                  ),
                                                  MapPinModel(
                                                    id: 2,
                                                    x: 0.16,
                                                    y: 0.60,
                                                    dx: -0.03,
                                                    dy: -0.02,
                                                    assetSvg:
                                                        "assets/icons/isoladellestorie/button2.svg",
                                                    hint: 'Radura delle Bacche',
                                                  ),
                                                  MapPinModel(
                                                    id: 3,
                                                    x: 0.11,
                                                    y: 0.30,
                                                    dx: 0.02,
                                                    dy: -0.01,
                                                    assetSvg:
                                                        "assets/icons/isoladellestorie/button3.svg",
                                                    hint: "Pozzo dell'Oracolo",
                                                  ),
                                                  MapPinModel(
                                                    id: 4,
                                                    x: 0.53,
                                                    y: 0.17,
                                                    dx: -0.02,
                                                    dy: -0.02,
                                                    assetSvg:
                                                        "assets/icons/isoladellestorie/button4.svg",
                                                    hint:
                                                        "Porta nell'Alabastro",
                                                  ),
                                                  MapPinModel(
                                                    id: 5,
                                                    x: 0.87,
                                                    y: 0.17,
                                                    dx: 0.02,
                                                    dy: 0.00,
                                                    assetSvg:
                                                        "assets/icons/isoladellestorie/button5.svg",
                                                    hint: 'Primo Anello',
                                                  ),
                                                  MapPinModel(
                                                    id: 6,
                                                    x: 0.87,
                                                    y: 0.40,
                                                    dx: 0.02,
                                                    dy: 0.00,
                                                    assetSvg:
                                                        "assets/icons/isoladellestorie/button6.svg",
                                                    hint: 'Secondo Anello',
                                                  ),
                                                  MapPinModel(
                                                    id: 7,
                                                    x: 0.92,
                                                    y: 0.62,
                                                    dx: 0.02,
                                                    dy: 0.00,
                                                    assetSvg:
                                                        "assets/icons/isoladellestorie/button7.svg",
                                                    hint: 'Terzo Anello',
                                                  ),
                                                  MapPinModel(
                                                    id: 8,
                                                    x: 0.97,
                                                    y: 0.84,
                                                    dx: 0.02,
                                                    dy: 0.00,
                                                    assetSvg:
                                                        "assets/icons/isoladellestorie/button8.svg",
                                                    hint: 'Quarto Anello',
                                                  ),
                                                  MapPinModel(
                                                    id: 9,
                                                    x: 0.65,
                                                    y: 0.98,
                                                    dx: 0.00,
                                                    dy: 0.00,
                                                    assetSvg:
                                                        "assets/icons/isoladellestorie/button9.svg",
                                                    hint:
                                                        'Cunicolo verso la Luce',
                                                  ),
                                                ],
                                                pinSizeFactor: 0.0495,
                                                onPinTap: _openExercise,
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 36),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0,
                                          ),
                                          child: Column(
                                            children: [
                                              const SizedBox(height: 4),
                                              RichText(
                                                textAlign: TextAlign.center,
                                                text: TextSpan(
                                                  style: GoogleFonts.arvo(
                                                    color:
                                                        HonooColor.onBackground,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                  children: [
                                                    const TextSpan(
                                                      text: 'Se vuoi di più, ',
                                                    ),
                                                    WidgetSpan(
                                                      alignment:
                                                          PlaceholderAlignment
                                                              .baseline,
                                                      baseline: TextBaseline
                                                          .alphabetic,
                                                      child: InkWell(
                                                        onTap: () {
                                                          Navigator.of(
                                                            context,
                                                          ).pushAndRemoveUntil(
                                                            MaterialPageRoute(
                                                              builder: (_) =>
                                                                  const FullIslandPage(),
                                                            ),
                                                            (route) => false,
                                                          );
                                                        },
                                                        child: Text(
                                                          'clicca qui',
                                                          style: GoogleFonts.arvo(
                                                            color: HonooColor
                                                                .onBackground,
                                                            fontSize: 18,
                                                            decoration:
                                                                TextDecoration
                                                                    .underline,
                                                            decorationColor:
                                                                HonooColor
                                                                    .onBackground,
                                                            decorationThickness:
                                                                3.0,
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

                  IslandToolbar(
                    onInfo: () => setState(() => infoVisible = !infoVisible),
                  ),
                ],
              ),
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
                      tooltip: 'Vai sulla Luna',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MoonPage(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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

  double _maxMapHeight(BuildContext context) {
    final media = MediaQuery.of(context);
    const double headerHeight = 60.0;
    const double introSpacing = 5.0;
    const double introTextHeight = 70.0;
    const double topSpacer = 36.0;
    const double bottomSpacer = 36.0;
    const double footerHeight = 80.0;
    const double safetyGap = 24.0; // margine extra per evitare sovrapposizioni

    final double reservedVertical =
        headerHeight +
        introSpacing +
        introTextHeight +
        topSpacer +
        bottomSpacer +
        footerHeight +
        safetyGap +
        media.padding.top +
        media.padding.bottom;
    final double availableHeight = media.size.height - reservedVertical;
    return math.max(availableHeight, 220.0);
  }
}

/// ============================================================================
///  MAPPA RESPONSIVE CON PIN SCALABILI (percentuali + offset)
/// ============================================================================

class MapPinModel {
  final int id; // 1..9
  final double x; // 0..1: ascissa nel viewBox dell'SVG
  final double y; // 0..1: ordinata nel viewBox dell'SVG
  final double
  dx; // offset orizzontale percentuale per spostare il pin rispetto al punto logico
  final double
  dy; // offset verticale percentuale per allineare il pin senza coprire il disegno
  final String assetSvg;
  final String hint;

  const MapPinModel({
    required this.id,
    required this.x,
    required this.y,
    this.dx = 0,
    this.dy = 0,
    required this.assetSvg,
    required this.hint,
  });
}

class IslandMapWithPins extends StatelessWidget {
  const IslandMapWithPins({
    super.key,
    required this.svgAsset,
    required this.aspectRatio,
    required this.pins,
    this.pinSizeFactor = 0.045,
    this.onPinTap,
    this.debugGrid = false,
  });

  final String svgAsset;
  final double aspectRatio;
  final List<MapPinModel> pins;
  final double pinSizeFactor;
  final void Function(int id)? onPinTap;
  final bool debugGrid;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final double availableWidth = constraints.maxWidth;
        final double renderWidth = availableWidth.isFinite && availableWidth > 0
            ? availableWidth
            : MediaQuery.of(ctx).size.width;
        final double safeAspectRatio = aspectRatio <= 0 ? 1 : aspectRatio;
        final double renderHeight = renderWidth / safeAspectRatio;

        final double pinVisualSize = (renderWidth * pinSizeFactor).clamp(
          24.0,
          160.0,
        );
        final double hitTargetSize = math.max(pinVisualSize, 40.0);

        return SizedBox(
          width: renderWidth,
          height: renderHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: SvgPicture.asset(svgAsset, fit: BoxFit.fill),
              ),
              if (debugGrid) ..._buildDebugGrid(renderWidth, renderHeight),
              ...pins.map((pin) {
                final double px =
                    (pin.x * renderWidth) +
                    (pin.dx * renderWidth) -
                    (hitTargetSize / 2);
                final double py =
                    (pin.y * renderHeight) +
                    (pin.dy * renderHeight) -
                    (hitTargetSize / 2);
                final VoidCallback? onPressed = onPinTap == null
                    ? null
                    : () => onPinTap!(pin.id);

                return Positioned(
                  left: px,
                  top: py,
                  child: Semantics(
                    label: pin.hint,
                    button: true,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: hitTargetSize,
                        minHeight: hitTargetSize,
                      ),
                      iconSize: pinVisualSize,
                      splashRadius: hitTargetSize / 2,
                      tooltip: pin.hint,
                      onPressed: onPressed,
                      icon: SvgPicture.asset(
                        pin.assetSvg,
                        width: pinVisualSize,
                        height: pinVisualSize,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildDebugGrid(double width, double height) {
    final lines = <Widget>[];
    for (int i = 1; i < 10; i++) {
      final double x = width * (i / 10);
      lines.add(
        Positioned(
          left: x,
          top: 0,
          bottom: 0,
          child: Container(
            width: 1,
            color: Colors.white.withValues(alpha: 0.25),
          ),
        ),
      );
    }
    for (int j = 1; j < 10; j++) {
      final double y = height * (j / 10);
      lines.add(
        Positioned(
          top: y,
          left: 0,
          right: 0,
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.25),
          ),
        ),
      );
    }
    return lines;
  }
}
