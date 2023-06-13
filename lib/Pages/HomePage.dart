import 'package:flutter/material.dart';
import 'package:honoo/Controller/Nim.dart';
import 'package:honoo/IsolaDelleStorie/Pages/IslandPage.dart';
import 'package:honoo/Pages/MoonPage.dart';
import 'package:honoo/Pages/NewHonooPage.dart';
import 'package:honoo/Pages/NimPage.dart';
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
      body: Column(
        children: [
          SizedBox(
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
          Expanded(
            child: SingleChildScrollView(
              child: SizedBox( 
                width: 100.w,
                child: Row(
                  children: [
                    Expanded(child: Container()),
                    Container(
                      constraints: DeviceController().isPhone() ? BoxConstraints(maxWidth: 100.w) : BoxConstraints(maxWidth: 50.w),
                      child:Column(
                        children: [
                          SizedBox(
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
                                  );
                                }),
                              ],
                            ),
                          ),
                          Text(
                            Utility().textHome1,
                            style: GoogleFonts.arvo(
                              color: HonooColor.onBackground,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const Padding(padding: EdgeInsets.all(15.0)),
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
                    Expanded(child: Container()),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: 105,
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
                  left: MediaQuery.of(context).size.width/2 + 80,
                  child: IconButton(icon: SvgPicture.asset(
                    "assets/icons/bottle.svg",
                    semanticsLabel: 'Bottiglia',
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
                  bottom: -16,
                  left: MediaQuery.of(context).size.width/2 - 200,
                  child: IconButton(icon: SvgPicture.asset(
                    width: 180,
                    height: 180,
                    "assets/icons/island.svg",
                    semanticsLabel: 'Chest',
                  ),
                  iconSize: 180,
                  splashRadius: 1,
                  //splashColor: Colors.transparent, // set splash color to transparent
                  //highlightColor: Colors.transparent, // set highlight color to transparent
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const IslandPage()),
                    );
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
                      MaterialPageRoute(builder: (context) => const ChestPage()),
                    );
                  }),
                ),
              ],
            )
          ),
        ],
      ),
    );
  }
}
