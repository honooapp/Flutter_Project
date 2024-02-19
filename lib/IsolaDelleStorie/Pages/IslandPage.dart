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

  bool infoVisible = true;

  @override
  Widget build(BuildContext context) {

    List<Widget> island = [

      SizedBox(
        width: 95.w,
        height: 400,
        child: SvgPicture.asset(
          "assets/icons/isoladellestorie/islandmap.svg",
        ),
      ),
      Positioned(
        bottom: - 8,
        left: MediaQuery.of(context).size.width/2 - 39.w,
        child: IconButton(
        icon: SvgPicture.asset(
          width: 40,
          height: 40,
          "assets/icons/isoladellestorie/button1.svg",
          semanticsLabel: 'Button 1',
        ),
        iconSize: 40,
        splashRadius: 30,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ExercisePage(exercise: ExerciseController().getExercise1(),)),
          );
        }),
      ),
      Positioned(
        bottom: 120,
        left: MediaQuery.of(context).size.width/2 - 50.w,
        child: IconButton(
        icon: SvgPicture.asset(
          width: 40,
          height: 40,
          "assets/icons/isoladellestorie/button2.svg",
          semanticsLabel: 'Button 2',
        ),
        iconSize: 40,
        splashRadius: 30,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ExercisePage(exercise: ExerciseController().getExercise2(),)),
          );
        }),
      ),
      Positioned(
        bottom: 260,
        left: 5,
        child: IconButton(
        icon: SvgPicture.asset(
          width: 40,
          height: 40,
          "assets/icons/isoladellestorie/button3.svg",
          semanticsLabel: 'Button 3',
        ),
        iconSize: 40,
        splashRadius: 30,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ExercisePage(exercise: ExerciseController().getExercise3(),)),
          );
        }),
      ),
      Positioned(
        bottom: 305,
        left: MediaQuery.of(context).size.width/2 - 12.w,
        child: IconButton(
        icon: SvgPicture.asset(
          width: 40,
          height: 40,
          "assets/icons/isoladellestorie/button4.svg",
          semanticsLabel: 'Button 4',
        ),
        iconSize: 40,
        splashRadius: 30,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ExercisePage(exercise: ExerciseController().getExercise4(),)),
          );
        }),
      ),
      Positioned(
        bottom: 305,
        left: MediaQuery.of(context).size.width/2 + 26.w,
        child: IconButton(
        icon: SvgPicture.asset(
          width: 40,
          height: 40,
          "assets/icons/isoladellestorie/button5.svg",
          semanticsLabel: 'Button 5',
        ),
        iconSize: 40,
        splashRadius: 30,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ExercisePage(exercise: ExerciseController().getExercise5(),)),
          );
        }),
      ),
      Positioned(
        bottom: 210,
        left: MediaQuery.of(context).size.width/2 + 27.w,
        child: IconButton(
        icon: SvgPicture.asset(
          width: 40,
          height: 40,
          "assets/icons/isoladellestorie/button6.svg",
          semanticsLabel: 'Button 6',
        ),
        iconSize: 40,
        splashRadius: 30,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ExercisePage(exercise: ExerciseController().getExercise6(),)),
          );
        }),
      ),
      Positioned(
        bottom: 125,
        left: MediaQuery.of(context).size.width/2 + 30.w,
        child: IconButton(
        icon: SvgPicture.asset(
          width: 40,
          height: 40,
          "assets/icons/isoladellestorie/button7.svg",
          semanticsLabel: 'Button 7',
        ),
        iconSize: 40,
        splashRadius: 30,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ExercisePage(exercise: ExerciseController().getExercise7(),)),
          );
        }),
      ),
      Positioned(
        bottom: 40,
        left: MediaQuery.of(context).size.width/2 + 33.5.w,
        child: IconButton(
        icon: SvgPicture.asset(
          width: 40,
          height: 40,
          "assets/icons/isoladellestorie/button8.svg",
          semanticsLabel: 'Button 8',
        ),
        iconSize: 40,
        splashRadius: 30,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ExercisePage(exercise: ExerciseController().getExercise8(),)),
          );
        }),
      ),
      Positioned(
        bottom: -10,
        left: MediaQuery.of(context).size.width/2,
        child: IconButton(
        icon: SvgPicture.asset(
          width: 40,
          height: 40,
          "assets/icons/isoladellestorie/button9.svg",
          semanticsLabel: 'Button 9',
        ),
        iconSize: 40,
        splashRadius: 30,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ExercisePage(exercise: ExerciseController().getExercise9(),)),
          );
        }),
      ),
    ];

    Positioned info = Positioned(
      top: 0,
      height: 80.h,
      left: 10.w,
      right: 10.w,
      child: Stack(
        children: [
          Visibility(
            visible: infoVisible,
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
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Visibility(
              visible: infoVisible,
              child: IconButton(
                icon: Icon(Icons.close),
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


    Positioned RulesButton = Positioned(
      bottom: -15,
      left: MediaQuery.of(context).size.width/2 + 110,
      child: IconButton(icon: SvgPicture.asset(
        "assets/icons/honoo_logo.svg",
        semanticsLabel: 'Logo',
      ),
      iconSize: 70,
      splashRadius: 30,
      onPressed: () {
        setState(() {
          infoVisible = !infoVisible;
        });
      }),
    );

    
    return Scaffold(
      backgroundColor: HonooColor.background,
      body: Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: SizedBox(
              height: 60,
              child: Center( 
                child:Text(
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
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox( 
                    width: 100.w,
                    child: Row(
                      children: [
                        Expanded(child: Container()),
                        Container(
                          constraints: DeviceController().isPhone() ? BoxConstraints(maxWidth: 100.w) : BoxConstraints(maxWidth: 50.w),
                          child:Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Padding(padding: EdgeInsets.only(top:5)),
                              SizedBox(
                                height: 70,
                                child:Stack(
                                  children: [                                
                                    Positioned(
                                      top: 0,
                                      right: MediaQuery.of(context).size.width/2 - 200,
                                      child: SizedBox(
                                        height: 60,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            IconButton(icon: SvgPicture.asset(
                                              "assets/icons/moon.svg",
                                              semanticsLabel: 'Moon',
                                            ),
                                            iconSize: 60,
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (context) => const MoonPage()),
                                                //MaterialPageRoute(builder: (context) => ComingSoonPage(header: Utility().readMoonHeader, quote: Utility().shakespeare, bibliography:  Utility().bibliography, )),
                                              );
                                            }),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned.fill(
                                      top: 0,
                                      child: Align(
                                        alignment: Alignment.topCenter, 
                                        child: IsolaDelleStoreContentManager.getRichText(IsolaDelleStoreContentManager.homeDescription),
                                      ),
                                    ),
                                  ],
                                )
                              ),
                              Stack(
                                children: island,
                              ),
                            ],
                          ),
                        ),
                        Expanded(child: Container()),
                      ],
                    ),
                  ),
                ),
                info,
              ],
            ),
          ),
          SizedBox(
            height: 80,
            child:Stack(
              children: [
                Positioned(
                  bottom: 50,
                  child: SizedBox(
                    height: 10,
                    width: MediaQuery.of(context).size.width,
                    child: Container(color: HonooColor.wave1,)
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: MediaQuery.of(context).size.width/2 + 60,
                  child: IconButton(icon: SvgPicture.asset(
                    "assets/icons/bottle.svg",
                    semanticsLabel: 'Bottle',
                  ),
                  iconSize: 70,
                  splashRadius: 40,
                  //splashColor: Colors.transparent, // set splash color to transparent
                  //highlightColor: Colors.transparent, // set highlight color to transparent
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NewHonooPage()),
                    );
                  }),
                ),
                Positioned(
                  bottom: 30,
                  child: SizedBox(
                    height: 20,
                    width: MediaQuery.of(context).size.width,
                    child: Container(color: HonooColor.wave2,)
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: SizedBox(
                    height: 30,
                    width: MediaQuery.of(context).size.width,
                    child: Container(color: HonooColor.wave3,)
                  ),
                ),
                
                Positioned(
                  bottom: 0,
                  left: MediaQuery.of(context).size.width/2 - 190,
                  child: IconButton(icon: SvgPicture.asset(
                    color: HonooColor.onBackground,
                    width: 40,
                    height: 40,
                    "assets/icons/home.svg",
                    semanticsLabel: 'Home',
                  ),
                  iconSize: 40,
                  splashRadius: 1,
                  //splashColor: Colors.transparent, // set splash color to transparent
                  //highlightColor: Colors.transparent, // set highlight color to transparent
                  onPressed: () {
                    Navigator.pop(context);
                  }),
                ),
                Positioned(
                  bottom: -20,
                  left: MediaQuery.of(context).size.width/2 - 40,
                  child: IconButton(icon: SvgPicture.asset(
                    "assets/icons/chest.svg",
                    semanticsLabel: 'Chest',
                  ),
                  iconSize: 70,
                  splashRadius: 40,
                  //splashColor: Colors.transparent, // set splash color to transparent
                  //highlightColor: Colors.transparent, // set highlight color to transparent
                  onPressed: () {
                    Navigator.push(
                      context,
                      //MaterialPageRoute(builder: (context) => const ChestPage()),
                      MaterialPageRoute(builder: (context) => ComingSoonPage(header: Utility().chestHeaderTemporary, quote: Utility().shakespeare, bibliography:  Utility().bibliography, )),

                    );
                  }),
                ),
                RulesButton,
              ],
            )
          ),
          /*
          SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: SvgPicture.asset(
                  "assets/icons/home.svg",
                  semanticsLabel: 'Home',
                ),
                iconSize: 60,
                splashRadius: 30,
                onPressed: () {
                  Navigator.pop(context);
                }),
                Padding(padding: EdgeInsets.only(left: 1.w)),
                IconButton(icon: SvgPicture.asset(
                  "assets/icons/isoladellestorie/gomitolo.svg",
                  semanticsLabel: 'Gomitolo',
                ),
                iconSize: 60,
                splashRadius: 30,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ComingSoonPage(header: Utility().honooHinooHeader, quote: Utility().shakespeare, bibliography:  Utility().bibliography, )),
                  );
                }),
                Padding(padding: EdgeInsets.only(left: 1.w)),
                IconButton(icon: SvgPicture.asset(
                  "assets/icons/isoladellestorie/garbuglio.svg",
                  semanticsLabel: 'Garbuglio',
                ),
                iconSize: 60,
                splashRadius: 30,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ComingSoonPage(header: Utility().honooHinooHeader, quote: Utility().shakespeare, bibliography:  Utility().bibliography, )),
                  );
                }),
                Padding(padding: EdgeInsets.only(left: 1.w)),
                IconButton(icon: SvgPicture.asset(
                  "assets/icons/isoladellestorie/conchiglia.svg",
                  semanticsLabel: 'Conghiglia',
                ),
                iconSize: 60,
                splashRadius: 30,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ComingSoonPage(header: Utility().othersHonooHinooHeader, quote: Utility().shakespeare, bibliography:  Utility().bibliography, )),
                  );
                }),
                Padding(padding: EdgeInsets.only(left: 1.w)),
                IconButton(icon: SvgPicture.asset(
                  "assets/icons/info.svg",
                  semanticsLabel: 'Info',
                ),
                iconSize: 60,
                splashRadius: 30,
                onPressed: () {
                  setState(() {
                    infoVisible = !infoVisible;
                  });
                }),
              ],
            ),
          ),
          */
        ],
      ),
    );
  }
}
