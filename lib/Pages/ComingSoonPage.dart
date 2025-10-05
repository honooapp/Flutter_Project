// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:honoo/Utility/FormattedText.dart';
import 'package:honoo/Utility/HonooColors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Utility/Utility.dart';
import 'package:sizer/sizer.dart';

import '../Controller/DeviceController.dart';

class ComingSoonPage extends StatefulWidget {
  ComingSoonPage(
      {super.key,
      required this.header,
      required this.quote,
      required this.bibliography});

  final String header;
  final String quote;
  final String bibliography;

  @override
  State<ComingSoonPage> createState() => _ComingSoonPageState();
}

class _ComingSoonPageState extends State<ComingSoonPage> {
  bool uiVisible = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HonooColor.background,
      body: Row(
        children: [
          Expanded(child: Container()),
          Container(
            constraints: DeviceController().isPhone()
                ? BoxConstraints(maxWidth: MediaQuery.of(context).size.width)
                : BoxConstraints(maxWidth: MediaQuery.of(context).size.width) *
                    0.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    height: 52,
                    child: Center(
                      child: Text(
                        Utility().appName,
                        style: GoogleFonts.libreFranklin(
                          color: HonooColor.secondary,
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(5.0),
                  ),
                  FormattedText(
                    inputText: widget.header,
                    color: HonooColor.onBackground,
                    fontSize: 18,
                  ),
                  Padding(
                    padding: EdgeInsets.all(30.0),
                  ),
                  SizedBox(
                    width: 80.w,
                    child: Text(
                      widget.quote,
                      style: GoogleFonts.libreFranklin(
                        color: HonooColor.wave4,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(10.0),
                  ),
                  SizedBox(
                    height: 20.h,
                    width: 80.w,
                    child: Text(
                      widget.bibliography,
                      style: GoogleFonts.libreFranklin(
                        color: HonooColor.wave4,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  Expanded(child: Container()),
                  SizedBox(
                    height: 60,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: SvgPicture.asset(
                            "assets/icons/home.svg",
                            semanticsLabel: 'Home',
                          ),
                          iconSize: 60,
                          splashRadius: 25,
                          tooltip: 'Indietro',
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
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
