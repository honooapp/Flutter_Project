import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:honoo/Utility/formatted_text.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Utility/utility.dart';
import 'package:sizer/sizer.dart';

import '../Controller/device_controller.dart';

class ComingSoonPage extends StatefulWidget {
  const ComingSoonPage(
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
  @override
  Widget build(BuildContext context) {
    final bool isPhone = DeviceController().isPhone();
    final double deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: HonooColor.background,
      body: Row(
        children: [
          const Spacer(),
          Container(
            constraints: BoxConstraints(
                maxWidth: isPhone ? deviceWidth : deviceWidth * 0.5),
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
                  const SizedBox(height: 5.0),
                  FormattedText(
                    inputText: widget.header,
                    color: HonooColor.onBackground,
                    fontSize: 18,
                  ),
                  const SizedBox(height: 30.0),
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
                  const SizedBox(height: 10.0),
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
                  const Spacer(),
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
          const Spacer(),
        ],
      ),
    );
  }
}
