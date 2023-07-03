import 'package:flutter/material.dart';
import 'package:honoo/IsolaDelleStorie/Utility/IsolaDelleStorieContentManager.dart';

import '../../Utility/HonooColors.dart';
import '../Entities/Exercise.dart';

class ExerciseController {
  static final ExerciseController _instance = ExerciseController._internal();

  factory ExerciseController() {
    return _instance;
  }

  ExerciseController._internal();

  List<int> listOfNumberOfExercises = [0,6,5,3,4,1,3,3,4];

  Map<String, Function> methodMap = {};

  void init () {
    methodMap = {
      "2.1": getExercise2_1,
      "2.2": getExercise2_2,
      "2.3": getExercise2_3,
      "2.4": getExercise2_4,
      "2.5": getExercise2_5,
      "2.6": getExercise2_6,
      "3.1": getExercise3_1,
      "3.2": getExercise3_2,
      "3.3": getExercise3_3,
      "3.4": getExercise3_4,
      "3.5": getExercise3_5,
      "4.1": getExercise4_1,
      "4.2": getExercise4_2,
      "4.3": getExercise4_3,
      "5.1": getExercise5_1,
      "5.2": getExercise5_2,
      "5.3": getExercise5_3,
      "5.4": getExercise5_4,
      "6.1": getExercise6_1,
      "7.1": getExercise7_1,
      "7.2": getExercise7_2,
      "7.3": getExercise7_3,
      "8.1": getExercise8_1,
      "8.2": getExercise8_2,
      "8.3": getExercise8_3,
      "9.1": getExercise9_1,
      "9.2": getExercise9_2,
      "9.3": getExercise9_3,
      "9.4": getExercise9_4,
    };
  }

  Exercise getExercise1() {
    return Exercise(
      1,
      IsolaDelleStoreContentManager.e_1_0_title,
      IsolaDelleStoreContentManager.e_1_0,
      'assets/icons/isoladellestorie/backgrounds/1grottarondini.png',
    );
  }

  Exercise getExercise2() {
    return Exercise(
      2,
      IsolaDelleStoreContentManager.e_2_0_title,
      IsolaDelleStoreContentManager.e_2_0,
      'assets/icons/isoladellestorie/backgrounds/2radurabacche.png',
    );
  }

  Exercise getExercise2_1() {
    return Exercise(
      2,
      IsolaDelleStoreContentManager.e_2_1_title,
      IsolaDelleStoreContentManager.e_2_1,
      'assets/icons/isoladellestorie/backgrounds/2radurabacche.png',
    );
  }

  Exercise getExercise2_2() {
    return Exercise(
      2,
      IsolaDelleStoreContentManager.e_2_2_title,
      IsolaDelleStoreContentManager.e_2_2,
      'assets/icons/isoladellestorie/backgrounds/2radurabacche.png',
    );
  }

  Exercise getExercise2_3() {
    return Exercise(
      2,
      IsolaDelleStoreContentManager.e_2_3_title,
      IsolaDelleStoreContentManager.e_2_3,
      'assets/icons/isoladellestorie/backgrounds/2radurabacche.png',
    );
  }

  Exercise getExercise2_4() {
    return Exercise(
      2,
      IsolaDelleStoreContentManager.e_2_4_title,
      IsolaDelleStoreContentManager.e_2_4,
      'assets/icons/isoladellestorie/backgrounds/2radurabacche.png',
    );
  }

  Exercise getExercise2_5() {
    return Exercise(
      2,
      IsolaDelleStoreContentManager.e_2_5_title,
      IsolaDelleStoreContentManager.e_2_5,
      'assets/icons/isoladellestorie/backgrounds/2radurabacche.png',
    );
  }

  Exercise getExercise2_6() {
    return Exercise(
      2,
      IsolaDelleStoreContentManager.e_2_6_title,
      IsolaDelleStoreContentManager.e_2_6,
      'assets/icons/isoladellestorie/backgrounds/2radurabacche.png',
    );
  }

  Exercise getExercise3() {
    return Exercise(
      3,
      IsolaDelleStoreContentManager.e_3_0_title,
      IsolaDelleStoreContentManager.e_3_0,
      'assets/icons/isoladellestorie/backgrounds/3pozzooracolo.png',
    );
  }

  Exercise getExercise3_1() {
    return Exercise(
      3,
      IsolaDelleStoreContentManager.e_3_1_title,
      IsolaDelleStoreContentManager.e_3_1,
      'assets/icons/isoladellestorie/backgrounds/3pozzooracolo.png',
    );
  }

  Exercise getExercise3_2() {
    return Exercise(
      3,
      IsolaDelleStoreContentManager.e_3_2_title,
      IsolaDelleStoreContentManager.e_3_2,
      'assets/icons/isoladellestorie/backgrounds/3pozzooracolo.png',
    );
  }

  Exercise getExercise3_3() {
    return Exercise(
      3,
      IsolaDelleStoreContentManager.e_3_3_title,
      IsolaDelleStoreContentManager.e_3_3,
      'assets/icons/isoladellestorie/backgrounds/3pozzooracolo.png',
    );
  }

  Exercise getExercise3_4() {
    return Exercise(
      3,
      IsolaDelleStoreContentManager.e_3_4_title,
      IsolaDelleStoreContentManager.e_3_4,
      'assets/icons/isoladellestorie/backgrounds/3pozzooracolo.png',
    );
  }

  Exercise getExercise3_5() {
    return Exercise(
      3,
      IsolaDelleStoreContentManager.e_3_5_title,
      IsolaDelleStoreContentManager.e_3_5,
      'assets/icons/isoladellestorie/backgrounds/3pozzooracolo.png',
    );
  }

  Exercise getExercise4() {
    return Exercise(
      4,
      IsolaDelleStoreContentManager.e_4_0_title,
      IsolaDelleStoreContentManager.e_4_0,
      'assets/icons/isoladellestorie/backgrounds/4portaalabastro.png',
    );
  }

  Exercise getExercise4_1() {
    return Exercise(
      4,
      IsolaDelleStoreContentManager.e_4_1_title,
      IsolaDelleStoreContentManager.e_4_1,
      'assets/icons/isoladellestorie/backgrounds/4portaalabastro.png',
    );
  }

  Exercise getExercise4_2() {
    return Exercise(
      4,
      IsolaDelleStoreContentManager.e_4_2_title,
      IsolaDelleStoreContentManager.e_4_2,
      'assets/icons/isoladellestorie/backgrounds/4portaalabastro.png',
    );
  }

  Exercise getExercise4_3() {
    return Exercise(
      4,
      IsolaDelleStoreContentManager.e_4_3_title,
      IsolaDelleStoreContentManager.e_4_3,
      'assets/icons/isoladellestorie/backgrounds/4portaalabastro.png',
    );
  }

  Exercise getExercise5() {
    return Exercise(
      5,
      IsolaDelleStoreContentManager.e_5_0_title,
      IsolaDelleStoreContentManager.e_5_0,
      'assets/icons/isoladellestorie/backgrounds/5primoanello.png',
    );
  }

  Exercise getExercise5_1() {
    return Exercise(
      5,
      IsolaDelleStoreContentManager.e_5_1_title,
      IsolaDelleStoreContentManager.e_5_1,
      'assets/icons/isoladellestorie/backgrounds/5primoanello.png',
    );
  }

  Exercise getExercise5_2() {
    return Exercise(
      5,
      IsolaDelleStoreContentManager.e_5_2_title,
      IsolaDelleStoreContentManager.e_5_2,
      'assets/icons/isoladellestorie/backgrounds/5primoanello.png',
    );
  }

  Exercise getExercise5_3() {
    return Exercise(
      5,
      IsolaDelleStoreContentManager.e_5_3_title,
      IsolaDelleStoreContentManager.e_5_3,
      'assets/icons/isoladellestorie/backgrounds/5primoanello.png',
    );
  }

  Exercise getExercise5_4() {
    return Exercise(
      5,
      IsolaDelleStoreContentManager.e_5_4_title,
      IsolaDelleStoreContentManager.e_5_4,
      'assets/icons/isoladellestorie/backgrounds/5primoanello.png',
    );
  }

  Exercise getExercise6() {
    return Exercise(
      6,
      IsolaDelleStoreContentManager.e_6_0_title,
      IsolaDelleStoreContentManager.e_6_0,
      'assets/icons/isoladellestorie/backgrounds/6secondoanello.png',
    );
  }

  Exercise getExercise6_1() {
    return Exercise(
      6,
      IsolaDelleStoreContentManager.e_6_1_title,
      IsolaDelleStoreContentManager.e_6_1,
      'assets/icons/isoladellestorie/backgrounds/6secondoanello.png',
    );
  }

  Exercise getExercise7() {
    return Exercise(
      7,
      IsolaDelleStoreContentManager.e_7_0_title,
      IsolaDelleStoreContentManager.e_7_0,
      'assets/icons/isoladellestorie/backgrounds/7terzoanello.png',
    );
  }

  Exercise getExercise7_1() {
    return Exercise(
      7,
      IsolaDelleStoreContentManager.e_7_1_title,
      IsolaDelleStoreContentManager.e_7_1,
      'assets/icons/isoladellestorie/backgrounds/7terzoanello.png',
    );
  }

  Exercise getExercise7_2() {
    return Exercise(
      7,
      IsolaDelleStoreContentManager.e_7_2_title,
      IsolaDelleStoreContentManager.e_7_2,
      'assets/icons/isoladellestorie/backgrounds/7terzoanello.png',
    );
  }

  Exercise getExercise7_3() {
    return Exercise(
      7,
      IsolaDelleStoreContentManager.e_7_3_title,
      IsolaDelleStoreContentManager.e_7_3,
      'assets/icons/isoladellestorie/backgrounds/7terzoanello.png',
    );
  }

  Exercise getExercise8() {
    return Exercise(
      8,
      IsolaDelleStoreContentManager.e_8_0_title,
      IsolaDelleStoreContentManager.e_8_0,
      'assets/icons/isoladellestorie/backgrounds/8quartoanello.png',
    );
  }

  Exercise getExercise8_1() {
    return Exercise(
      8,
      IsolaDelleStoreContentManager.e_8_1_title,
      IsolaDelleStoreContentManager.e_8_1,
      'assets/icons/isoladellestorie/backgrounds/8quartoanello.png',
    );
  }

  Exercise getExercise8_2() {
    return Exercise(
      8,
      IsolaDelleStoreContentManager.e_8_2_title,
      IsolaDelleStoreContentManager.e_8_2,
      'assets/icons/isoladellestorie/backgrounds/8quartoanello.png',
    );
  }

  Exercise getExercise8_3() {
    return Exercise(
      8,
      IsolaDelleStoreContentManager.e_8_3_title,
      IsolaDelleStoreContentManager.e_8_3,
      'assets/icons/isoladellestorie/backgrounds/8quartoanello.png',
    );
  }

  Exercise getExercise9() {
    return Exercise(
      9,
      IsolaDelleStoreContentManager.e_9_0_title,
      IsolaDelleStoreContentManager.e_9_0,
      'assets/icons/isoladellestorie/backgrounds/9cunicololuce.png',
    );
  }

  Exercise getExercise9_1() {
    return Exercise(
      9,
      IsolaDelleStoreContentManager.e_9_1_title,
      IsolaDelleStoreContentManager.e_9_1,
      'assets/icons/isoladellestorie/backgrounds/9cunicololuce.png',
    );
  }

  Exercise getExercise9_2() {
    return Exercise(
      9,
      IsolaDelleStoreContentManager.e_9_2_title,
      IsolaDelleStoreContentManager.e_9_2,
      'assets/icons/isoladellestorie/backgrounds/9cunicololuce.png',
    );
  }

  Exercise getExercise9_3() {
    return Exercise(
      9,
      IsolaDelleStoreContentManager.e_9_3_title,
      IsolaDelleStoreContentManager.e_9_3,
      'assets/icons/isoladellestorie/backgrounds/9cunicololuce.png',
    );
  }

  Exercise getExercise9_4() {
    return Exercise(
      9,
      IsolaDelleStoreContentManager.e_9_4_title,
      IsolaDelleStoreContentManager.e_9_4,
      'assets/icons/isoladellestorie/backgrounds/9cunicololuce.png',
    );
  }

  List<Widget> getExerciseButtons (Exercise exercise, Function handleButtonPressed) {
    final int numberOfExercises = listOfNumberOfExercises[exercise.parentId-1];
    List<Widget> ret = [];
    switch (exercise.parentId) {
      case 2:
      case 3:
      case 4:
      case 5:
      case 6:
      case 7:
      case 8:
      case 9:
        for (var i = 0; i < numberOfExercises; i++) {
          var methodName = "${exercise.parentId}.${i+1}";
          ret.add(
            RawMaterialButton(
              onPressed: () => handleButtonPressed(methodName),
              shape: CircleBorder(),
              fillColor: HonooColor.wave4,
              constraints: BoxConstraints.tight(Size(40, 40)),
              child: Text(
                methodName ,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: HonooColor.onBackground,
                ),
              ),
            ),
          );
        }
      break;
      default:

    }
    return ret;
  }



}
