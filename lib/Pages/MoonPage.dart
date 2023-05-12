import 'package:flutter/material.dart';
import 'package:flutter_project/Controller/HonooController.dart';
import 'package:flutter_project/UI/HonooCard.dart';
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
      backgroundColor: const Color(0xFF000026),
      body: Column(
        children: [
          SizedBox(
            height: 60,
            child: Center( 
              child:Text(
                Utility().appName,
                style: GoogleFonts.arvo(
                  color: const Color(0xFF9E172F),
                  fontSize: 40,
                  fontWeight: FontWeight.w400,
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
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton(icon: SvgPicture.asset(
                            "assets/icons/home.svg",
                            semanticsLabel: 'Home',
                          ),
                          iconSize: 60,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => HomePage()),
                            );
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
