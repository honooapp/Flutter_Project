import 'package:flutter/material.dart';
import 'package:flutter_project/Controller/DeviceController.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
      backgroundColor: Color(0xFF000026),
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
                    child: Text(
                      Utility().appName,
                      style: GoogleFonts.arvo(
                        color: Color(0xFF9E172F),
                        fontSize: 40,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SizedBox( 
                        width: MediaQuery.of(context).size.width,
                        child: Text(
                          Utility().text1,
                          style: GoogleFonts.arvo(
                            color: const Color(0xFFFFFFFF),
                            fontSize: 18,
                            fontWeight: FontWeight.w200,
                          ),
                          textAlign: TextAlign.center,
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
                            MaterialPageRoute(builder: (context) => HomePage()),
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
