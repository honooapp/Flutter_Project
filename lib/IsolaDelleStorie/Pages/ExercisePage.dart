// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:honoo/IsolaDelleStorie/Controller/ExerciseController.dart';
import 'package:honoo/IsolaDelleStorie/Entities/Exercise.dart';
import 'package:honoo/Utility/FormattedText.dart';
import 'package:honoo/Utility/HonooColors.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:sizer/sizer.dart';

import '../../Pages/ComingSoonPage.dart';
import '../../Utility/Utility.dart';
import '../Utility/IsolaDelleStorieContentManager.dart';
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
  static const double _buttonOffsetX = 0;
  static const double _buttonOffsetY = 0;
  static const double _buttonGap = 8.0;
  static const double _pathOverlapFactor = 0.5;
  static const List<TrackPinModel> _trackPins = [
    TrackPinModel(
      id: 1,
      x: 0.22,
      y: 0.10,
      dx: 0.00,
      dy: -0.02,
      assetSvg: "assets/icons/isoladellestorie/button1.svg",
    ),
    TrackPinModel(
      id: 2,
      x: 0.40,
      y: 0.10,
      dx: 0.00,
      dy: -0.02,
      assetSvg: "assets/icons/isoladellestorie/button2.svg",
    ),
    TrackPinModel(
      id: 3,
      x: 0.58,
      y: 0.10,
      dx: 0.00,
      dy: -0.02,
      assetSvg: "assets/icons/isoladellestorie/button3.svg",
    ),
    TrackPinModel(
      id: 4,
      x: 0.77,
      y: 0.10,
      dx: 0.00,
      dy: -0.02,
      assetSvg: "assets/icons/isoladellestorie/button4.svg",
    ),
    TrackPinModel(
      id: 5,
      x: 0.98,
      y: 0.50,
      dx: 0.00,
      dy: 0.00,
      assetSvg: "assets/icons/isoladellestorie/button5.svg",
    ),
    TrackPinModel(
      id: 6,
      x: 0.78,
      y: 0.85,
      dx: 0.00,
      dy: 0.02,
      assetSvg: "assets/icons/isoladellestorie/button6.svg",
    ),
    TrackPinModel(
      id: 7,
      x: 0.60,
      y: 0.85,
      dx: 0.00,
      dy: 0.02,
      assetSvg: "assets/icons/isoladellestorie/button7.svg",
    ),
    TrackPinModel(
      id: 8,
      x: 0.42,
      y: 0.85,
      dx: 0.00,
      dy: 0.02,
      assetSvg: "assets/icons/isoladellestorie/button8.svg",
    ),
    TrackPinModel(
      id: 9,
      x: 0.24,
      y: 0.85,
      dx: 0.00,
      dy: 0.02,
      assetSvg: "assets/icons/isoladellestorie/button9.svg",
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

  Widget _buildTrackSection() {
    const double verticalPadding = 12.0;
    const double baseHorizontalMargin = 24.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final media = MediaQuery.of(context);
        final double viewportHeight = media.size.height;
        final double availableWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0 ? constraints.maxWidth : media.size.width;
        final double targetHeightBase = viewportHeight / 6;
        final double targetHeight = math.max(targetHeightBase + 20.0, (verticalPadding * 2) + 32.0);

        final bool ultraTight = availableWidth < 360;
        final double gapWidth = _buttonGap;
        final double horizontalMargin = baseHorizontalMargin;
        final double gapW = ultraTight ? gapWidth * 0.85 : gapWidth;
        final double hM = ultraTight ? horizontalMargin * 0.85 : horizontalMargin;

        final double sideButtonSize = math.max(32.0, math.min(_iconButtonSize, targetHeight * 0.45));
        final double trackHeight = math.max(targetHeight - (verticalPadding * 2), sideButtonSize);
        final double trackWidth = trackHeight * _trackAspectRatio;

        final double horizontalOverlap =
            (_iconButtonSize * _pathOverlapFactor).clamp(0.0, hM);
        final double drawWidth = trackWidth + horizontalOverlap;
        final double effectiveOverlap = math.min(horizontalOverlap, drawWidth * 0.3);
        final double pinVisualSize = math.max(24.0, math.min(sideButtonSize, _iconButtonSize));
        final double drawWidthBase = math.max(0.0, drawWidth - effectiveOverlap);
        final double pinBleedX = uiVisible
            ? math.max(pinVisualSize * 0.5, effectiveOverlap + pinVisualSize * 0.25)
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

        return SizedBox(
          height: targetHeight,
          width: availableWidth,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildTrackButtons(sideButtonSize),
                SizedBox(width: gapW),
                Flexible(
                  fit: FlexFit.tight,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: leftPadding,
                      right: hM,
                      top: verticalPadding,
                      bottom: verticalPadding,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: drawWidthVisible,
                        height: trackAreaHeight,
                        child: pathContent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrackButtons(double size) {
    final double splash = math.max(24.0, size * 0.6);
    final BoxConstraints constraints = BoxConstraints.tightFor(width: size, height: size);

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
        if (uiVisible)
          tightIconButton(
            svg: "assets/icons/isoladellestorie/islandhome.svg",
            semantics: "Torna all'Isola",
            onPressed: () => Navigator.pop(context),
          ),

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

    Function handleButtonPressed = (String buttonText) {
      if (ExerciseController().methodMap.containsKey(buttonText)) {
        final Function method = ExerciseController().methodMap[buttonText]!;
        final Exercise ret = method();
        setState(() {
          _exercise = ret;
        });
      } else {
        print("Invalid method name");
      }
    };

    final List<Widget> subExercises =
        ExerciseController().getExerciseButtons(_exercise, handleButtonPressed, context);


    return Scaffold(
      backgroundColor: HonooColor.background,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              _exercise.exerciseImage,
              fit: BoxFit.cover,
            ),
          ),
          // Content
          Positioned.fill(
            child: Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  //Title
                  Visibility(
                    visible: uiVisible,
                    child: SizedBox(
                      height: 60,
                      child: Center(
                        child:Text(
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
                  Padding( padding: EdgeInsets.all(8.0),),
                  // Scrollable Text Box
                  Visibility(
                    visible: uiVisible,
                      child: Expanded(
                      child: Container(
                        child: Center(
                          child: Container(
                            child: ClipRect(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  width: 80.w,
                                  padding: EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    color: HonooColor.wave1.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child:
                                  // SingleChildScrollView(
                                  //   //child:IsolaDelleStoreContentManager.getRichText(_exercise.exerciseDescription),
                                  //   child:FormattedText(inputText: _exercise.exerciseDescription, color: HonooColor.onBackground, fontSize: 18,),
                                  // ),
                                  ListView(
                                    //padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.width/2), //per versione telefono
                                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height > MediaQuery.of(context).size.width ? MediaQuery.of(context).size.width/4 : MediaQuery.of(context).size.height/4 ),
                                    children: [
                                        FormattedText(
                                          inputText: _exercise.exerciseDescription,
                                          color: HonooColor.onBackground,
                                          fontSize: 18,
                                        ),
                                        if (_exercise.exerciseIcon != null)
                                          //SizedBox(height: 10),
                                          IconButton(
                                            icon: SvgPicture.asset(
                                              _exercise.exerciseIcon ?? "",
                                              colorFilter: const ColorFilter.mode(
                                                HonooColor.onBackground,
                                                BlendMode.srcIn,
                                              ),
                                              semanticsLabel:
                                                  _exercise.exerciseIconName,
                                            ),
                                          iconSize: 70,
                                          splashRadius: 40,
                                          tooltip: _exercise.exerciseIconName ?? '',
                                              onPressed: () {
                                                if (_exercise.exerciseIconName == "Dado") {
                                                  String header;

                                                  if (_exercise.exerciseTitle == IsolaDelleStoreContentManager.e_3_1_title) {
                                                    header = Utility().dadoTemporaryM;
                                                  } else if (_exercise.exerciseTitle == IsolaDelleStoreContentManager.e_5_3_title) {
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
                                         // SizedBox(height: 10),
                                          FormattedText(
                                            inputText: _exercise.exerciseDescriptionMore ?? "",
                                            color: HonooColor.onBackground,
                                            fontSize: 18,
                                          ),
                                      ],
                                  ),

                                ),
                              ),
                            ),
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
                  /*Stack(
                    children: <Widget>[
                      Positioned.fill(
                          child: SizedBox(
                          width: 90.w,
                          height: 130,
                          child: SvgPicture.asset(
                            "assets/icons/isoladellestorie/path.svg",
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment(-0.9, -0.1), // change .2 based on your need
                        child: RawMaterialButton(
                          onPressed: () {
                            setState(() {
                              _exercise = ExerciseController().getExercise6();
                            });
                          },
                          shape: CircleBorder(),
                          fillColor: HonooColor.wave4,
                          constraints: BoxConstraints.tight(Size(20, 20)),
                          child: Text(
                            "6" ,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: HonooColor.onBackground,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),*/
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
