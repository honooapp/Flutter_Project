import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';


import '../Controller/DeviceController.dart';
import '../UI/HonooBuilder.dart';
import '../Utility/Utility.dart';
import 'package:sizer/sizer.dart';

import 'HomePage.dart';


class NewHonooPage extends StatefulWidget {
  const NewHonooPage({super.key});


  @override
  State<NewHonooPage> createState() => _NewHonooPageState();
}

class _NewHonooPageState extends State<NewHonooPage> {

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
                      child: SizedBox(
                        height: 70.h,
                        child: const HonooBuilder(),
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
                              MaterialPageRoute(builder: (context) => const HomePage()),
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
