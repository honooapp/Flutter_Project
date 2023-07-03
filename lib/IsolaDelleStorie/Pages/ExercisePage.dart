// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:honoo/IsolaDelleStorie/Controller/ExerciseController.dart';
import 'package:honoo/IsolaDelleStorie/Entities/Exercise.dart';
import 'package:honoo/IsolaDelleStorie/Utility/IsolaDelleStorieContentManager.dart';
import 'package:honoo/Utility/HonooColors.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../Controller/DeviceController.dart';
import 'package:sizer/sizer.dart';


class ExercisePage extends StatefulWidget {
  ExercisePage({super.key, required this.exercise});

  Exercise exercise;


  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {

  bool uiVisible = true;

  @override
  Widget build(BuildContext context) {

    Function handleButtonPressed = (String buttonText) {
    if (ExerciseController().methodMap.containsKey(buttonText)) {
      Function method = ExerciseController().methodMap[buttonText]!;
      Exercise ret = method();
      setState(() {
        widget.exercise = ret;
      });
    } else {
      print("Invalid method name");
    }
  };

    List<Widget> subExercises = ExerciseController().getExerciseButtons(widget.exercise, handleButtonPressed);

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
                widget.exercise = ExerciseController().getExercise1();
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
                widget.exercise = ExerciseController().getExercise2();
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
                widget.exercise = ExerciseController().getExercise3();
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
                widget.exercise = ExerciseController().getExercise4();
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
                widget.exercise = ExerciseController().getExercise5();
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
                widget.exercise = ExerciseController().getExercise6();
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
                widget.exercise = ExerciseController().getExercise7();
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
                widget.exercise = ExerciseController().getExercise8();
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
                widget.exercise = ExerciseController().getExercise9();
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
              widget.exercise.exerciseImage,
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
                          widget.exercise.exerciseTitle,
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
                                  child: SingleChildScrollView(
                                    child:IsolaDelleStoreContentManager.getRichText(widget.exercise.exerciseDescription),
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
                  subExercises.isNotEmpty ?
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: subExercises,
                  ) : Container(),
                  Padding( padding: EdgeInsets.all(8.0),),
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
                              widget.exercise = ExerciseController().getExercise6();
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
