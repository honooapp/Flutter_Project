import 'package:flutter/material.dart';
import 'package:honoo/Utility/HonooColors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';


import '../Controller/DeviceController.dart';
import '../UI/HonooBuilder.dart';
import '../Utility/Utility.dart';
import 'package:sizer/sizer.dart';



class NewHonooPage extends StatefulWidget {
  const NewHonooPage({super.key});


  @override
  State<NewHonooPage> createState() => _NewHonooPageState();
}

class _NewHonooPageState extends State<NewHonooPage> {

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
          Row(
            children: [
              Expanded(child: Container()),
              Container(
                constraints: DeviceController().isPhone() ? BoxConstraints(maxWidth: 100.w, maxHeight: 100.h -120) : BoxConstraints(maxWidth: 50.w, maxHeight: 100.h - 120),
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(icon: SvgPicture.asset(
                            "assets/icons/home.svg",
                            semanticsLabel: 'Home',
                          ),
                          iconSize: 60,
                          splashRadius: 25,
                          onPressed: () {
                            /*
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const HomePage()),
                            );
                            */
                            Navigator.pop(context);
                          }),
                          Padding(padding: EdgeInsets.only(left: 20.w),),
                          IconButton(icon: SvgPicture.asset(
                            "assets/icons/ok.svg",
                            semanticsLabel: 'Home',
                          ),
                          iconSize: 60,
                          splashRadius: 25,
                          onPressed: () {
                            /*Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const HomePage()),
                            );*/
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
