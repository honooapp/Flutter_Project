import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/IsolaDelleStorie/Utility/isola_delle_storie_content_manager.dart';

import '../../Utility/honoo_colors.dart';
import '../Entities/exercise.dart';

class ExerciseController {
  static final ExerciseController _instance = ExerciseController._internal();

  factory ExerciseController() {
    return _instance;
  }

  ExerciseController._internal();

  List<int> listOfNumberOfSubExercises = [
    1,
    7,
    5,
    3,
    4,
    1,
    3,
    3,
    4
  ]; //inizia da 0

  Map<String, Exercise Function()> methodMap = <String, Exercise Function()>{};

  void init() {
    methodMap = <String, Exercise Function()>{
      "1.1": getExercise1_1,
      "2.1": getExercise2_1,
      "2.2": getExercise2_2,
      "2.3": getExercise2_3,
      "2.4": getExercise2_4,
      "2.5": getExercise2_5,
      "2.6": getExercise2_6,
      "2.7": getExercise2_7,
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
      "1",
      1,
      IsolaDelleStoreContentManager.e10Title,
      IsolaDelleStoreContentManager.e10,
      'assets/icons/isoladellestorie/backgrounds/1grottarondini.png',
    );
  }

  Exercise getExercise1_1() {
    return Exercise(
      "1.1",
      1,
      IsolaDelleStoreContentManager.e11Title,
      IsolaDelleStoreContentManager.e11,
      'assets/icons/isoladellestorie/backgrounds/1grottarondini.png',
    );
  }

  Exercise getExercise2() {
    return Exercise(
      "2",
      2,
      IsolaDelleStoreContentManager.e20Title,
      IsolaDelleStoreContentManager.e20,
      'assets/icons/isoladellestorie/backgrounds/2radurabacche.png',
    );
  }

  Exercise getExercise2_1() {
    return Exercise(
      "2.1",
      2,
      IsolaDelleStoreContentManager.e21Title,
      IsolaDelleStoreContentManager.e21,
      'assets/icons/isoladellestorie/backgrounds/2radurabacche.png',
    );
  }

  Exercise getExercise2_2() {
    return Exercise(
      "2.2",
      2,
      IsolaDelleStoreContentManager.e22Title,
      IsolaDelleStoreContentManager.e22,
      'assets/icons/isoladellestorie/backgrounds/2radurabacche.png',
    );
  }

  Exercise getExercise2_3() {
    return Exercise(
      "2.3",
      2,
      IsolaDelleStoreContentManager.e23Title,
      IsolaDelleStoreContentManager.e23,
      'assets/icons/isoladellestorie/backgrounds/2radurabacche.png',
    );
  }

  Exercise getExercise2_4() {
    return Exercise(
      "2.4",
      2,
      IsolaDelleStoreContentManager.e24Title,
      IsolaDelleStoreContentManager.e24,
      'assets/icons/isoladellestorie/backgrounds/2radurabacche.png',
    );
  }

  Exercise getExercise2_5() {
    return Exercise(
      "2.5",
      2,
      IsolaDelleStoreContentManager.e25Title,
      IsolaDelleStoreContentManager.e25,
      'assets/icons/isoladellestorie/backgrounds/2radurabacche.png',
    );
  }

  Exercise getExercise2_6() {
    return Exercise(
      "2.6",
      2,
      IsolaDelleStoreContentManager.e26Title,
      IsolaDelleStoreContentManager.e26,
      'assets/icons/isoladellestorie/backgrounds/2radurabacche.png',
    );
  }

  Exercise getExercise2_7() {
    return Exercise(
      "2.7",
      2,
      IsolaDelleStoreContentManager.e27Title,
      IsolaDelleStoreContentManager.e27,
      'assets/icons/isoladellestorie/backgrounds/2radurabacche.png',
    );
  }

  Exercise getExercise3() {
    return Exercise(
      "3",
      3,
      IsolaDelleStoreContentManager.e30Title,
      IsolaDelleStoreContentManager.e30,
      'assets/icons/isoladellestorie/backgrounds/3pozzooracolo.png',
    );
  }

  Exercise getExercise3_1() {
    return Exercise(
        "3.1",
        3,
        IsolaDelleStoreContentManager.e31Title,
        IsolaDelleStoreContentManager.e31First,
        'assets/icons/isoladellestorie/backgrounds/3pozzooracolo.png',
        exerciseDescriptionMore: IsolaDelleStoreContentManager.e31Second,
        exerciseIcon: 'assets/icons/dado.svg',
        exerciseIconName: 'Dado');
  }

  Exercise getExercise3_2() {
    return Exercise(
        "3.2",
        3,
        IsolaDelleStoreContentManager.e32Title,
        IsolaDelleStoreContentManager.e32First,
        'assets/icons/isoladellestorie/backgrounds/3pozzooracolo.png',
        exerciseDescriptionMore: IsolaDelleStoreContentManager.e32Second,
        exerciseIcon: 'assets/icons/dado.svg',
        exerciseIconName: 'Dado');
  }

  Exercise getExercise3_3() {
    return Exercise(
        "3.3",
        3,
        IsolaDelleStoreContentManager.e33Title,
        IsolaDelleStoreContentManager.e33First,
        'assets/icons/isoladellestorie/backgrounds/3pozzooracolo.png',
        exerciseDescriptionMore: IsolaDelleStoreContentManager.e33Second,
        exerciseIcon: 'assets/icons/dado.svg',
        exerciseIconName: 'Dado');
  }

  Exercise getExercise3_4() {
    return Exercise(
      "3.4",
      3,
      IsolaDelleStoreContentManager.e34Title,
      IsolaDelleStoreContentManager.e34,
      'assets/icons/isoladellestorie/backgrounds/3pozzooracolo.png',
    );
  }

  Exercise getExercise3_5() {
    return Exercise(
      "3.5",
      3,
      IsolaDelleStoreContentManager.e35Title,
      IsolaDelleStoreContentManager.e35,
      'assets/icons/isoladellestorie/backgrounds/3pozzooracolo.png',
    );
  }

  Exercise getExercise4() {
    return Exercise(
      "4",
      4,
      IsolaDelleStoreContentManager.e40Title,
      IsolaDelleStoreContentManager.e40,
      'assets/icons/isoladellestorie/backgrounds/4portaalabastro.png',
    );
  }

  Exercise getExercise4_1() {
    return Exercise(
      "4.1",
      4,
      IsolaDelleStoreContentManager.e41Title,
      IsolaDelleStoreContentManager.e41,
      'assets/icons/isoladellestorie/backgrounds/4portaalabastro.png',
    );
  }

  Exercise getExercise4_2() {
    return Exercise(
      "4.2",
      4,
      IsolaDelleStoreContentManager.e42Title,
      IsolaDelleStoreContentManager.e42,
      'assets/icons/isoladellestorie/backgrounds/4portaalabastro.png',
    );
  }

  Exercise getExercise4_3() {
    return Exercise(
      "4.3",
      4,
      IsolaDelleStoreContentManager.e43Title,
      IsolaDelleStoreContentManager.e43,
      'assets/icons/isoladellestorie/backgrounds/4portaalabastro.png',
    );
  }

  Exercise getExercise5() {
    return Exercise(
      "5",
      5,
      IsolaDelleStoreContentManager.e50Title,
      IsolaDelleStoreContentManager.e50,
      'assets/icons/isoladellestorie/backgrounds/5primoanello.png',
    );
  }

  Exercise getExercise5_1() {
    return Exercise(
        "5.1",
        5,
        IsolaDelleStoreContentManager.e51Title,
        IsolaDelleStoreContentManager.e51First,
        'assets/icons/isoladellestorie/backgrounds/5primoanello.png',
        exerciseDescriptionMore: IsolaDelleStoreContentManager.e51Second,
        exerciseIcon: 'assets/icons/dado.svg',
        exerciseIconName: 'Dado');
  }

  Exercise getExercise5_2() {
    return Exercise(
        "5.2",
        5,
        IsolaDelleStoreContentManager.e52Title,
        IsolaDelleStoreContentManager.e52First,
        'assets/icons/isoladellestorie/backgrounds/5primoanello.png',
        exerciseDescriptionMore: IsolaDelleStoreContentManager.e52Second,
        exerciseIcon: 'assets/icons/dado.svg',
        exerciseIconName: 'Dado');
  }

  Exercise getExercise5_3() {
    return Exercise(
        "5.3",
        5,
        IsolaDelleStoreContentManager.e53Title,
        IsolaDelleStoreContentManager.e53First,
        'assets/icons/isoladellestorie/backgrounds/5primoanello.png',
        exerciseDescriptionMore: IsolaDelleStoreContentManager.e53Second,
        exerciseIcon: 'assets/icons/dado.svg',
        exerciseIconName: 'Dado');
  }

  Exercise getExercise5_4() {
    return Exercise(
      "5.4",
      5,
      IsolaDelleStoreContentManager.e54Title,
      IsolaDelleStoreContentManager.e54,
      'assets/icons/isoladellestorie/backgrounds/5primoanello.png',
    );
  }

  Exercise getExercise6() {
    return Exercise(
      "6",
      6,
      IsolaDelleStoreContentManager.e60Title,
      IsolaDelleStoreContentManager.e60,
      'assets/icons/isoladellestorie/backgrounds/6secondoanello.png',
    );
  }

  Exercise getExercise6_1() {
    return Exercise(
      "6.1",
      6,
      IsolaDelleStoreContentManager.e61Title,
      IsolaDelleStoreContentManager.e61,
      'assets/icons/isoladellestorie/backgrounds/6secondoanello.png',
    );
  }

  Exercise getExercise7() {
    return Exercise(
      "7",
      7,
      IsolaDelleStoreContentManager.e70Title,
      IsolaDelleStoreContentManager.e70,
      'assets/icons/isoladellestorie/backgrounds/7terzoanello.png',
    );
  }

  Exercise getExercise7_1() {
    return Exercise(
      "7.1",
      7,
      IsolaDelleStoreContentManager.e71Title,
      IsolaDelleStoreContentManager.e71,
      'assets/icons/isoladellestorie/backgrounds/7terzoanello.png',
    );
  }

  Exercise getExercise7_2() {
    return Exercise(
      "7.2",
      7,
      IsolaDelleStoreContentManager.e72Title,
      IsolaDelleStoreContentManager.e72,
      'assets/icons/isoladellestorie/backgrounds/7terzoanello.png',
    );
  }

  Exercise getExercise7_3() {
    return Exercise(
      "7.3",
      7,
      IsolaDelleStoreContentManager.e73Title,
      IsolaDelleStoreContentManager.e73,
      'assets/icons/isoladellestorie/backgrounds/7terzoanello.png',
    );
  }

  Exercise getExercise8() {
    return Exercise(
      "8",
      8,
      IsolaDelleStoreContentManager.e80Title,
      IsolaDelleStoreContentManager.e80,
      'assets/icons/isoladellestorie/backgrounds/8quartoanello.png',
    );
  }

  Exercise getExercise8_1() {
    return Exercise(
      "8.1",
      8,
      IsolaDelleStoreContentManager.e81Title,
      IsolaDelleStoreContentManager.e81,
      'assets/icons/isoladellestorie/backgrounds/8quartoanello.png',
    );
  }

  Exercise getExercise8_2() {
    return Exercise(
      "8.2",
      8,
      IsolaDelleStoreContentManager.e82Title,
      IsolaDelleStoreContentManager.e82,
      'assets/icons/isoladellestorie/backgrounds/8quartoanello.png',
    );
  }

  Exercise getExercise8_3() {
    return Exercise(
      "8.3",
      8,
      IsolaDelleStoreContentManager.e83Title,
      IsolaDelleStoreContentManager.e83,
      'assets/icons/isoladellestorie/backgrounds/8quartoanello.png',
    );
  }

  Exercise getExercise9() {
    return Exercise(
      "9",
      9,
      IsolaDelleStoreContentManager.e90Title,
      IsolaDelleStoreContentManager.e90,
      'assets/icons/isoladellestorie/backgrounds/9cunicololuce.png',
    );
  }

  Exercise getExercise9_1() {
    return Exercise(
      "9.1",
      9,
      IsolaDelleStoreContentManager.e91Title,
      IsolaDelleStoreContentManager.e91,
      'assets/icons/isoladellestorie/backgrounds/9cunicololuce.png',
    );
  }

  Exercise getExercise9_2() {
    return Exercise(
      "9.2",
      9,
      IsolaDelleStoreContentManager.e92Title,
      IsolaDelleStoreContentManager.e92,
      'assets/icons/isoladellestorie/backgrounds/9cunicololuce.png',
    );
  }

  Exercise getExercise9_3() {
    return Exercise(
      "9.3",
      9,
      IsolaDelleStoreContentManager.e93Title,
      IsolaDelleStoreContentManager.e93,
      'assets/icons/isoladellestorie/backgrounds/9cunicololuce.png',
    );
  }

  Exercise getExercise9_4() {
    return Exercise(
      "9.4",
      9,
      IsolaDelleStoreContentManager.e94Title,
      IsolaDelleStoreContentManager.e94,
      'assets/icons/isoladellestorie/backgrounds/9cunicololuce.png',
    );
  }

  List<Widget> getExerciseButtons(Exercise exercise,
      ValueChanged<String> handleButtonPressed, BuildContext context) {
    final int numberOfExercises =
        listOfNumberOfSubExercises[exercise.parentId - 1];
    List<Widget> ret = [];
    switch (exercise.parentId) {
      case 1:
      case 2:
      case 3:
      case 4:
      case 5:
      case 6:
      case 7:
      case 8:
      case 9:
        for (var i = 0; i < numberOfExercises; i++) {
          var methodName = "${exercise.parentId}.${i + 1}";
          ret.add(
            RawMaterialButton(
              onPressed: () => handleButtonPressed(methodName),
              shape: const CircleBorder(),
              fillColor: HonooColor.wave4,
              constraints: BoxConstraints.tight(const Size(40, 40)),
              child: Text(
                methodName,
                style: GoogleFonts.libreFranklin(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: HonooColor.onBackground,
                ),
              ),
            ),
          );
        }
        break;
      default:
    }
    /*
    switch (exercise.id) {
      case "3.1": //1 - 144
        ret.add(
          const RawMaterialButton(
            onPressed: () => (){
              showDialog(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: Text('Number Popup'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '123', // Replace this with the number you want to display
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 20),
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            shape: CircleBorder(),
            fillColor: HonooColor.wave4,
            constraints: BoxConstraints.tight(Size(40, 40)),
            child: SvgPicture.asset(
              "assets/icons/dice.svg",
              semanticsLabel: 'Dice',
            ),
          ),
        );
      break;
      case "2.4": //2 - 12
      break;
      case "5.1": //1 - 10
      break;
      default:

    }
    */
    return ret;
  }

  List<Exercise> getAllExercises() {
    return [];
  }
}
