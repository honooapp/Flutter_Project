import 'package:flutter/material.dart';
import 'package:flutter_project/Controller/HonooController.dart';
import 'package:flutter_project/UI/HonooCard.dart';
import 'package:flutter_project/Utility/HonooColors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';


import '../Controller/DeviceController.dart';
import '../Entites/Honoo.dart';
import '../Utility/Utility.dart';
import 'package:sizer/sizer.dart';

import 'HomePage.dart';


class ChestPage extends StatefulWidget {
  const ChestPage({super.key});


  @override
  State<ChestPage> createState() => _ChestPageState();
}

class _ChestPageState extends State<ChestPage> {

  @override
  Widget build(BuildContext context) {

    List<List<List<Honoo>>> honooList = HonooController().getChestHonoo();
    
    List<List<Honoo>> personalHonoo = honooList[0];
    List<List<Honoo>> answerHonoo = honooList[1];

    List<CarouselSlider> personalHonooSliders = [];
    List<CarouselSlider> answerHonooSliders = [];
    for (int i = 0; i < personalHonoo.length; i++) {
      List<Widget> personalHonooCards = [];
      for (int j = 0; j < personalHonoo[i].length; j++) {
        personalHonooCards.add(HonooCard(honoo: personalHonoo[i][j]));
      }
      personalHonooSliders.add(CarouselSlider(
        options: CarouselOptions(
          height: 70.h,
          aspectRatio: 9/16,
          enlargeCenterPage: true,
          enableInfiniteScroll: false,
          scrollDirection: Axis.vertical,
        ),
        items: personalHonooCards,
      ));
    }
    for (int i = 0; i < answerHonoo.length; i++) {
      List<Widget> answerHonooCards = [];
      for (int j = 0; j < answerHonoo[i].length; j++) {
        answerHonooCards.add(HonooCard(honoo: answerHonoo[i][j]));
      }
      answerHonooSliders.add(CarouselSlider(
        options: CarouselOptions(
          height: 70.h,
          aspectRatio: 9/16,
          enlargeCenterPage: true,
          enableInfiniteScroll: false,
          scrollDirection: Axis.vertical,
        ),
        items: answerHonooCards,
      ));
    }
    List<Widget> honooCards = [];
    honooCards.insertAll(0, personalHonooSliders);
    honooCards.insert(honooCards.length, Card(
      child: Container(
        width: 100.w,
        height: 70.h,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                Utility().chestText,
                style: GoogleFonts.arvo(
                  color: HonooColor.onTertiary,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ));
    honooCards.insertAll(honooCards.length, answerHonooSliders);


    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 214, 214, 214),
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
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(child: Container()),
              Container(
                constraints: DeviceController().isPhone() ? BoxConstraints(maxWidth: 100.w, maxHeight: 100.h -60) : BoxConstraints(maxWidth: 50.w, maxHeight: 100.h - 60),
                child:Column(
                  children: [
                    Expanded(
                      child: CarouselSlider(
                        options: CarouselOptions(
                          initialPage: personalHonoo.length,
                          height: 70.h,
                          aspectRatio: 9/16,
                          enlargeCenterPage: true,
                          enableInfiniteScroll: false,
                        ),
                        items: honooCards,
                      ),
                    ),
                    SizedBox(
                      height: 60,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(icon: SvgPicture.asset(
                            color: HonooColor.onTertiary,
                            "assets/icons/home.svg",
                            semanticsLabel: 'Home',
                          ),
                          iconSize: 60,
                          splashRadius: 25,
                          onPressed: () {
                            Navigator.pop(context);
                          }),
                          Padding(padding: EdgeInsets.only(left: 5.w)),
                          IconButton(icon: SvgPicture.asset(
                            "assets/icons/heart.svg",
                            semanticsLabel: 'Heart',
                          ),
                          iconSize: 60,
                          splashRadius: 25,
                          onPressed: () {
                            //TODO: Add to favorites
                          }),
                          Padding(padding: EdgeInsets.only(left: 5.w)),
                          IconButton(icon: SvgPicture.asset(
                            color: HonooColor.onTertiary,
                            "assets/icons/reply.svg",
                            semanticsLabel: 'Reply',
                          ),
                          iconSize: 60,
                          splashRadius: 25,
                          onPressed: () {
                            //TODO: reply
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: Container()),
            ],
          ),
        ],
      ),
    );
  }
}
