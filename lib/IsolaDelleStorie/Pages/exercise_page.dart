import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:honoo/IsolaDelleStorie/Controller/exercise_controller.dart';
import 'package:honoo/IsolaDelleStorie/Entities/exercise.dart';
import 'package:honoo/Utility/formatted_text.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:sizer/sizer.dart';

import '../../Pages/coming_soon_page.dart';
import '../../Utility/utility.dart';
import '../Utility/isola_delle_storie_content_manager.dart';
import '../../Widgets/map/responsive_track_with_pins.dart';

class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key, required this.exercise});

  final Exercise exercise;

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  late Exercise _exercise;
  bool uiVisible = true;

  static const double _iconButtonSize = 40.0;
  static const double _trackAspectRatio = 257 / 59;
  // Offsets are measured in logical pixels at the base icon size; we scale them with the buttons.
  static const double _buttonOffsetX = 50;
  static const double _buttonOffsetY = -22;
  static const double _buttonGap = 20.0;
  static const double _pathOverlapFactor = 0.5;
  static const List<TrackPinModel> _trackPins = [
    TrackPinModel(
      id: 1,
      x: 0.22,
      y: 0.10,
      dx: 0.00,
      dy: -0.02,
      assetSvg: "assets/icons/isoladellestorie/button1.svg",
      hint: 'Grotta delle Rondini',
    ),
    TrackPinModel(
      id: 2,
      x: 0.40,
      y: 0.10,
      dx: 0.00,
      dy: -0.02,
      assetSvg: "assets/icons/isoladellestorie/button2.svg",
      hint: 'Radura delle Bacche',
    ),
    TrackPinModel(
      id: 3,
      x: 0.58,
      y: 0.10,
      dx: 0.00,
      dy: -0.02,
      assetSvg: "assets/icons/isoladellestorie/button3.svg",
      hint: "Pozzo dell'Oracolo",
    ),
    TrackPinModel(
      id: 4,
      x: 0.77,
      y: 0.10,
      dx: 0.00,
      dy: -0.02,
      assetSvg: "assets/icons/isoladellestorie/button4.svg",
      hint: "Porta nell'Alabastro",
    ),
    TrackPinModel(
      id: 5,
      x: 0.98,
      y: 0.50,
      dx: 0.00,
      dy: 0.00,
      assetSvg: "assets/icons/isoladellestorie/button5.svg",
      hint: 'Primo Anello',
    ),
    TrackPinModel(
      id: 6,
      x: 0.78,
      y: 0.85,
      dx: 0.00,
      dy: 0.02,
      assetSvg: "assets/icons/isoladellestorie/button6.svg",
      hint: 'Secondo Anello',
    ),
    TrackPinModel(
      id: 7,
      x: 0.60,
      y: 0.85,
      dx: 0.00,
      dy: 0.02,
      assetSvg: "assets/icons/isoladellestorie/button7.svg",
      hint: 'Terzo Anello',
    ),
    TrackPinModel(
      id: 8,
      x: 0.42,
      y: 0.85,
      dx: 0.00,
      dy: 0.02,
      assetSvg: "assets/icons/isoladellestorie/button8.svg",
      hint: 'Quarto Anello',
    ),
    TrackPinModel(
      id: 9,
      x: 0.24,
      y: 0.85,
      dx: 0.00,
      dy: 0.02,
      assetSvg: "assets/icons/isoladellestorie/button9.svg",
      hint: 'Cunicolo verso la Luce',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _exercise = widget.exercise;
  }

  void _openExerciseById(int id) {
    final controller = ExerciseController();
    Exercise next = _exercise;
    switch (id) {
      case 1:
        next = controller.getExercise1();
        break;
      case 2:
        next = controller.getExercise2();
        break;
      case 3:
        next = controller.getExercise3();
        break;
      case 4:
        next = controller.getExercise4();
        break;
      case 5:
        next = controller.getExercise5();
        break;
      case 6:
        next = controller.getExercise6();
        break;
      case 7:
        next = controller.getExercise7();
        break;
      case 8:
        next = controller.getExercise8();
        break;
      case 9:
        next = controller.getExercise9();
        break;
      default:
        next = controller.getExercise1();
    }
    setState(() {
      _exercise = next;
    });
  }

  Widget _buildDescriptionCard(BuildContext context) {
    final media = MediaQuery.of(context);
    final double bottomPadding = media.size.height > media.size.width
        ? media.size.width / 4
        : media.size.height / 4;

    return Container(
      key: ValueKey<String>('desc_${_exercise.id}'),
      width: 80.w,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: HonooColor.wave1.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8.0),
      ),
      alignment: Alignment.center,
      child: ListView(
        key: ValueKey<String>('desc_list_${_exercise.id}'),
        padding: EdgeInsets.only(bottom: bottomPadding),
        physics: const BouncingScrollPhysics(),
        children: [
          FormattedText(
            inputText: _exercise.exerciseDescription,
            color: HonooColor.onBackground,
            fontSize: 18,
          ),
          if (_exercise.exerciseIcon != null)
            IconButton(
                icon: SvgPicture.asset(
                  _exercise.exerciseIcon ?? "",
                  colorFilter: const ColorFilter.mode(
                    HonooColor.onBackground,
                    BlendMode.srcIn,
                  ),
                  semanticsLabel: _exercise.exerciseIconName,
                ),
                iconSize: 70,
                splashRadius: 40,
                tooltip: _exercise.exerciseIconName ?? '',
                onPressed: () {
                  if (_exercise.exerciseIconName == "Dado") {
                    String header;

                    if (_exercise.exerciseTitle ==
                        IsolaDelleStoreContentManager.e31Title) {
                      header = Utility().dadoTemporaryM;
                    } else if (_exercise.exerciseTitle ==
                        IsolaDelleStoreContentManager.e53Title) {
                      header = Utility().dadoTemporaryL;
                    } else {
                      header = Utility().dadoTemporary;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ComingSoonPage(
                          header: header,
                          quote: Utility().shakespeare,
                          bibliography: Utility().bibliography,
                        ),
                      ),
                    );
                  }
                }),
          if (_exercise.exerciseDescriptionMore != null)
            FormattedText(
              inputText: _exercise.exerciseDescriptionMore ?? "",
              color: HonooColor.onBackground,
              fontSize: 18,
            ),
        ],
      ),
    );
  }

  Widget _buildTrackSection() {
    const double verticalPadding = 12.0;
    const double baseHorizontalMargin = 24.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final media = MediaQuery.of(context);
        final double viewportHeight = media.size.height;
        final double availableWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : media.size.width;
        final double targetHeightBase = viewportHeight / 6;
        final double targetHeight =
            math.max(targetHeightBase + 20.0, (verticalPadding * 2) + 32.0);

        final bool ultraTight = availableWidth < 360;
        const double gapWidth = _buttonGap;
        const double horizontalMargin = baseHorizontalMargin;
        final double gapW = ultraTight ? gapWidth * 0.85 : gapWidth;
        final double hM =
            ultraTight ? horizontalMargin * 0.85 : horizontalMargin;

        final double sideButtonSize =
            math.max(32.0, math.min(_iconButtonSize, targetHeight * 0.45));
        final double trackHeight =
            math.max(targetHeight - (verticalPadding * 2), sideButtonSize);
        final double trackWidth = trackHeight * _trackAspectRatio;

        final double horizontalOverlap =
            (_iconButtonSize * _pathOverlapFactor).clamp(0.0, hM);
        final double drawWidth = trackWidth + horizontalOverlap;
        final double effectiveOverlap =
            math.min(horizontalOverlap, drawWidth * 0.3);
        final double pinVisualSize =
            math.max(24.0, math.min(sideButtonSize, _iconButtonSize));
        final double drawWidthBase =
            math.max(0.0, drawWidth - effectiveOverlap);
        final double pinBleedX = uiVisible
            ? math.max(
                pinVisualSize * 0.5, effectiveOverlap + pinVisualSize * 0.25)
            : 0.0;
        final double pinBleedY = uiVisible ? pinVisualSize * 0.35 : 0.0;
        final double drawWidthVisible = drawWidthBase + pinBleedX;
        final double trackAreaHeight = trackHeight + pinBleedY;
        final double leftPadding = math.max(0.0, hM - effectiveOverlap);

        final Widget pathContent = ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(top: pinBleedY * 0.4),
              child: SizedBox(
                width: drawWidth,
                height: trackHeight,
                child: uiVisible
                    ? ResponsiveTrackWithPins(
                        trackSvgAsset: "assets/icons/isoladellestorie/path.svg",
                        trackAspectRatio: _trackAspectRatio,
                        pins: _trackPins,
                        pinSizeFactor: 0.0495,
                        pinFixedSize: pinVisualSize,
                        onPinTap: _openExerciseById,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        );

        final Widget trackWithMargin = Padding(
          padding: EdgeInsets.only(
            left: leftPadding,
            right: hM,
            top: verticalPadding,
            bottom: verticalPadding,
          ),
          child: SizedBox(
            width: drawWidthVisible,
            height: trackAreaHeight,
            child: pathContent,
          ),
        );

        final double trackWidthWithMargin = leftPadding + drawWidthVisible + hM;
        final double trackHeightWithMargin =
            trackAreaHeight + (verticalPadding * 2);
        final Widget buttonColumn = _buildTrackButtons(sideButtonSize);
        final int visibleButtons = uiVisible ? 2 : 1;
        final double buttonColumnHeight =
            (visibleButtons * sideButtonSize) + (uiVisible ? _buttonGap : 0.0);
        final double baseWidth = sideButtonSize + gapW + trackWidthWithMargin;
        final double baseHeight =
            math.max(buttonColumnHeight, trackHeightWithMargin);
        final double sizeScale = sideButtonSize / _iconButtonSize;
        final double buttonsBaseTop = (baseHeight - buttonColumnHeight) * 0.5;
        final double trackBaseTop = (baseHeight - trackHeightWithMargin) * 0.5;
        final double buttonsLeft = _buttonOffsetX * sizeScale;
        final double buttonsTop = buttonsBaseTop + (_buttonOffsetY * sizeScale);

        final Widget controlStack = SizedBox(
          width: baseWidth,
          height: baseHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: sideButtonSize + gapW,
                top: trackBaseTop,
                child: trackWithMargin,
              ),
              Positioned(
                left: buttonsLeft,
                top: buttonsTop,
                child: buttonColumn,
              ),
            ],
          ),
        );

        return SizedBox(
          height: targetHeight,
          width: availableWidth,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: controlStack,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrackButtons(double size) {
    final double splash = math.max(24.0, size * 0.6);
    final BoxConstraints constraints =
        BoxConstraints.tightFor(width: size, height: size);

    Widget tightIconButton({
      required String svg,
      required String semantics,
      required VoidCallback? onPressed,
    }) {
      return ConstrainedBox(
        constraints: constraints,
        child: IconButton(
          onPressed: onPressed,
          icon: SvgPicture.asset(
            svg,
            width: size,
            height: size,
            semanticsLabel: semantics,
          ),
          iconSize: size,
          padding: EdgeInsets.zero,
          constraints: constraints,
          visualDensity: VisualDensity.compact,
          splashRadius: splash,
          tooltip: semantics,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (uiVisible) ...[
          tightIconButton(
            svg: "assets/icons/isoladellestorie/islandhome.svg",
            semantics: "Torna all'Isola",
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: _buttonGap),
        ],
        tightIconButton(
          svg: "assets/icons/isoladellestorie/offUI.svg",
          semantics: "Mostra o nascondi il percorso",
          onPressed: () => setState(() => uiVisible = !uiVisible),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    void handleButtonPressed(String buttonText) {
      final Exercise Function()? method =
          ExerciseController().methodMap[buttonText];
      if (method != null) {
        setState(() {
          _exercise = method();
        });
      } else {
        debugPrint('Invalid method name: $buttonText');
      }
    }

    final List<Widget> subExercises = ExerciseController()
        .getExerciseButtons(_exercise, handleButtonPressed, context);

    final Widget pageContent = KeyedSubtree(
      key: ValueKey<String>(_exercise.id),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              _exercise.exerciseImage,
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Visibility(
                  visible: uiVisible,
                  child: SizedBox(
                    height: 60,
                    child: Center(
                      child: Text(
                        _exercise.exerciseTitle,
                        style: GoogleFonts.libreFranklin(
                          color: HonooColor.secondary,
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),
                Visibility(
                  visible: uiVisible,
                  child: Expanded(
                    child: Center(
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: _buildDescriptionCard(context),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),
                if (subExercises.isNotEmpty && uiVisible)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12.0,
                      runSpacing: 12.0,
                      children: subExercises,
                    ),
                  ),
                const SizedBox(height: 8.0),
                _buildTrackSection(),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: HonooColor.background,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            fit: StackFit.expand,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: pageContent,
      ),
    );
  }
}
