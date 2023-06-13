import 'package:flutter/material.dart';
import 'package:honoo/IsolaDelleStorie/Entities/Exercise.dart';
import 'package:honoo/IsolaDelleStorie/Utility/IsolaDelleStorieContentManager.dart';
import 'package:honoo/Pages/MoonPage.dart';
import 'package:honoo/Pages/NewHonooPage.dart';
import 'package:honoo/Utility/HonooColors.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
                IsolaDelleStoreContentManager.homeTitle,
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
                          Padding(padding: EdgeInsets.only(top: 5.h)),
                          IsolaDelleStoreContentManager.getRichText(IsolaDelleStoreContentManager.homeDescription),
                          Padding(padding: EdgeInsets.only(top: 5.h)),
                        ],
                      ),
                    ),
                    Expanded(child: Container()),
                  ],
                ),
              ),
            ),
          ),
          
        ],
      ),
    );
  }
}
