import 'package:flutter/material.dart';
import 'package:honoo/Controller/DeviceController.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../Utility/HonooColors.dart';
import '../Utility/Utility.dart';
import 'HomePage.dart';



class PlaceholderPage extends StatefulWidget {
  const PlaceholderPage({super.key});

  @override
  State<PlaceholderPage> createState() => _PlaceholderPageState();
}

class _PlaceholderPageState extends State<PlaceholderPage> {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: HonooColor.background,
      body: Row(
        children: [
          Expanded(child: Container()),
          Container(
            constraints: DeviceController().isPhone() ? BoxConstraints(maxWidth: MediaQuery.of(context).size.width) : BoxConstraints(maxWidth: MediaQuery.of(context).size.width) * 0.5,
            child:Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
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
                  // Expanded(
                  //   child: SingleChildScrollView(
                  //     child: SizedBox(
                  //       width: MediaQuery.of(context).size.width,
                  //       child: Text(
                  //         Utility().text1,
                  //         style: GoogleFonts.arvo(
                  //           color: HonooColor.onBackground,
                  //           fontSize: 18,
                  //           fontWeight: FontWeight.w200,
                  //         ),
                  //         textAlign: TextAlign.center,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.arvo(
                              color: HonooColor.onBackground,
                              fontSize: 18,
                              fontWeight: FontWeight.w200,
                            ),
                            children: [
                              TextSpan(
                                text: Utility().text1_first, // text
                              ),
                              WidgetSpan(
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: 3),
                                  child: Image.asset(
                                    "assets/icons/performance.png",
                                    height: 70,
                                  ),
                                ),
                                alignment: PlaceholderAlignment.middle,
                              ),
                              // WidgetSpan(
                              //   child: Image.asset(
                              //     "assets/icons/performance.png",
                              //     height: 70,
                              //   ),
                              //   alignment: PlaceholderAlignment.middle,
                              // ),
                              TextSpan(
                                text: Utility().text1_second, // text
                              ),
                              WidgetSpan(
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: 3),
                                  child: Image.asset(
                                    "assets/icons/luna.png",
                                    height: 70,
                                  ),
                                ),
                                alignment: PlaceholderAlignment.middle,
                              ),
                              TextSpan(
                                text: Utility().text1_third, // text
                              ),
                              WidgetSpan(
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: 3),
                                  child: Image.asset(
                                    "assets/icons/isola.png",
                                    height: 70,
                                  ),
                                ),
                                alignment: PlaceholderAlignment.middle,
                              ),
                              TextSpan(
                                text: Utility().text1_fourth, // text
                              ),
                              WidgetSpan(
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: 3),
                                  child: Image.asset(
                                    "assets/icons/performance.png",
                                    height: 70,
                                  ),
                                ),
                                alignment: PlaceholderAlignment.middle,
                              ),
                              TextSpan(
                                text: Utility().text1_fifth, // text
                              ),
                              WidgetSpan(
                                child: Image.asset(
                                  "assets/icons/logo_honoo.png",
                                  height: 45,
                                ),
                                alignment: PlaceholderAlignment.middle,
                              ),
                              TextSpan(
                                text: Utility().text1_six, // text
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 60,
                    child: Row(
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
          ),
          Expanded(child: Container()),
        ],
      ),
    );
  }
}
