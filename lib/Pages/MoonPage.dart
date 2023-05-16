import 'package:flutter/material.dart';
import 'package:honoo/Controller/HonooController.dart';
import 'package:honoo/UI/HonooCard.dart';
import 'package:honoo/Utility/HonooColors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';


import '../Controller/DeviceController.dart';
import '../Utility/Utility.dart';
import 'package:sizer/sizer.dart';

import 'HomePage.dart';


class MoonPage extends StatefulWidget {
  const MoonPage({super.key});


  @override
  State<MoonPage> createState() => _MoonPageState();
}

class _MoonPageState extends State<MoonPage> {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: HonooColor.tertiary,
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
                          height: 70.h,
                          aspectRatio: 9/16,
                          enlargeCenterPage: true,
                          enableInfiniteScroll: false,
                        ),
                        items: HonooController().getMoonHonoo().map((i) {
                          return Builder(
                            builder: (BuildContext context) {
                              return HonooCard(honoo: i);
                            },
                          );
                        }).toList(),
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
