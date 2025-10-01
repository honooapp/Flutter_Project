// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

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


class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key, required this.exercise});

  final Exercise exercise;


  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  late Exercise _exercise;
  bool uiVisible = true;

  @override
  void initState() {
    super.initState();
    _exercise = widget.exercise;
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

    List<Widget> mainPath = [
      Center(
        child: SizedBox(
          width: 90.w,
          height: 130,
          child: Visibility(
            visible: uiVisible,
            child: SvgPicture.asset(
              "assets/icons/isoladellestorie/path.svg",
            ),
          ),
        ),
      ),
      Positioned(
        top: 0.5.h,
        left: 0,
        child: Visibility(
          visible: uiVisible,
          child: IconButton(
            icon: SvgPicture.asset(
              width: 40,
              height: 40,
              "assets/icons/isoladellestorie/islandhome.svg",
              semanticsLabel: 'Home Isola delle storie',
            ),
            iconSize: 40,
            splashRadius: 30,
            tooltip: "Torna all'Isola",
            onPressed: () {
              Navigator.pop(context);
            }
          ),
        ),
      ),
      Positioned(
        top: 8.h,
        left: 0,
        child: IconButton(
        icon: SvgPicture.asset(
          width: 40,
          height: 40,
          "assets/icons/isoladellestorie/offUI.svg",
          semanticsLabel: 'Home Isola delle storie',
        ),
        iconSize: 40,
        splashRadius: 30,
        tooltip: 'Mostra o nascondi il percorso',
        onPressed: () {
          setState(() {
            uiVisible = !uiVisible;
          });
        }),
      ),
      Visibility(
        visible: uiVisible,
        child: Positioned(
          top: 1.h,
          left: 20.w,
          child: RawMaterialButton(
            onPressed: () {
              setState(() {
                _exercise = ExerciseController().getExercise1();
              });
            },
            shape: CircleBorder(),
            fillColor: HonooColor.wave4,
            constraints: BoxConstraints.tight(Size(40, 40)),
            child: Text(
              "1" ,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: HonooColor.onBackground,
              ),
            ),
          ),
        ),
      ),
      Visibility(
        visible: uiVisible,
        child: Positioned(
          top: 1.h,
          left: 38.w,
          child: RawMaterialButton(
            onPressed: () {
              setState(() {
                _exercise = ExerciseController().getExercise2();
              });
            },
            shape: CircleBorder(),
            fillColor: HonooColor.wave4,
            constraints: BoxConstraints.tight(Size(40, 40)),
            child: Text(
              "2" ,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: HonooColor.onBackground,
              ),
            ),
          ),
        ),
      ),
      Visibility(
        visible: uiVisible,
        child: Positioned(
          top: 1.h,
          left: 56.w,
          child: RawMaterialButton(
            onPressed: () {
              setState(() {
                _exercise = ExerciseController().getExercise3();
              });
            },
            shape: CircleBorder(),
            fillColor: HonooColor.wave4,
            constraints: BoxConstraints.tight(Size(40, 40)),
            child: Text(
              "3" ,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: HonooColor.onBackground,
              ),
            ),
          ),
        ),
      ),
      Visibility(
        visible: uiVisible,
        child: Positioned(
          top: 1.h,
          left: 74.w,
          child: RawMaterialButton(
            onPressed: () {
              setState(() {
                _exercise = ExerciseController().getExercise4();
              });
            },
            shape: CircleBorder(),
            fillColor: HonooColor.wave4,
            constraints: BoxConstraints.tight(Size(40, 40)),
            child: Text(
              "4" ,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: HonooColor.onBackground,
              ),
            ),
          ),
        ),
      ),
      Visibility(
        visible: uiVisible,
        child: Positioned(
          top: 5.h,
          left: 86.w,
          child: RawMaterialButton(
            onPressed: () {
              setState(() {
                _exercise = ExerciseController().getExercise5();
              });
            },
            shape: CircleBorder(),
            fillColor: HonooColor.wave4,
            constraints: BoxConstraints.tight(Size(40, 40)),
            child: Text(
              "5" ,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: HonooColor.onBackground,
              ),
            ),
          ),
        ),
      ),
      Visibility(
        visible: uiVisible,
        child: Positioned(
          top: 9.h,
          left: 74.w,
          child: RawMaterialButton(
            onPressed: () {
              setState(() {
                _exercise = ExerciseController().getExercise6();
              });
            },
            shape: CircleBorder(),
            fillColor: HonooColor.wave4,
            constraints: BoxConstraints.tight(Size(40, 40)),
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
      ),
      Visibility(
        visible: uiVisible,
        child: Positioned(
          top: 9.h,
          left: 56.w,
          child: RawMaterialButton(
            onPressed: () {
              setState(() {
                _exercise = ExerciseController().getExercise7();
              });
            },
            shape: CircleBorder(),
            fillColor: HonooColor.wave4,
            constraints: BoxConstraints.tight(Size(40, 40)),
            child: Text(
              "7" ,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: HonooColor.onBackground,
              ),
            ),
          ),
        ),
      ),
      Visibility(
        visible: uiVisible,
        child: Positioned(
          top: 9.h,
          left: 38.w,
          child: RawMaterialButton(
            onPressed: () {
              setState(() {
                _exercise = ExerciseController().getExercise8();
              });
            },
            shape: CircleBorder(),
            fillColor: HonooColor.wave4,
            constraints: BoxConstraints.tight(Size(40, 40)),
            child: Text(
              "8" ,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: HonooColor.onBackground,
              ),
            ),
          ),
        ),
      ),
      Visibility(
        visible: uiVisible,
          child: Positioned(
          top: 9.h,
          left: 20.w,
          child: RawMaterialButton(
            onPressed: () {
              setState(() {
                _exercise = ExerciseController().getExercise9();
              });
            },
            shape: CircleBorder(),
            fillColor: HonooColor.wave4,
            constraints: BoxConstraints.tight(Size(40, 40)),
            child: Text(
              "9" ,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: HonooColor.onBackground,
              ),
            ),
          ),
        ),
      ),
    ];

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
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
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
                                    color: Colors.white.withOpacity(0.3),
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
                  Visibility(
                    visible: !uiVisible,
                    child: Expanded(
                      child: Container(),
                    ),
                  ),
                  SizedBox(height: 16.0),
                  // Circular Buttons
                  subExercises.isNotEmpty && uiVisible ?
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: subExercises,
                  ) : Container(),
                  Padding( padding: EdgeInsets.all(16.0),),
                  Stack(
                    children: mainPath,
                  ),
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
