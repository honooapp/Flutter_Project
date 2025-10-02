import 'package:flutter/material.dart';
import 'package:honoo/Controller/DeviceController.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../Utility/HonooColors.dart';
import '../Utility/Utility.dart';
import '../Widgets/Background.dart';
import 'HomePage.dart';

class PlaceholderPage extends StatefulWidget {
  const PlaceholderPage({super.key});

  @override
  State<PlaceholderPage> createState() => _PlaceholderPageState();
}

class _PlaceholderPageState extends State<PlaceholderPage> {

  @override
  Widget build(BuildContext context) {
    final isPhone = DeviceController().isPhone();
    final maxWidth = MediaQuery.of(context).size.width;

    // Contenuto principale, usato in entrambi i layout
    final Widget content = Center(
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
          Expanded(
            child: SingleChildScrollView(
              child: SizedBox(
                width: maxWidth,
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.arvo(
                      color: HonooColor.onBackground,
                      fontSize: 18,
                      fontWeight: FontWeight.w200,
                    ),
                    children: [
                      TextSpan(text: Utility().text1_first),
                      WidgetSpan(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 3),
                          child: Image.asset("assets/icons/performance.png", height: 70),
                        ),
                        alignment: PlaceholderAlignment.middle,
                      ),
                      TextSpan(text: Utility().text1_second),
                      WidgetSpan(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 3),
                          child: Image.asset("assets/icons/luna.png", height: 70),
                        ),
                        alignment: PlaceholderAlignment.middle,
                      ),
                      TextSpan(text: Utility().text1_third),
                      WidgetSpan(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 3),
                          child: Image.asset("assets/icons/isola.png", height: 70),
                        ),
                        alignment: PlaceholderAlignment.middle,
                      ),
                      TextSpan(text: Utility().text1_fourth),
                      WidgetSpan(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 3),
                          child: Image.asset("assets/icons/performance.png", height: 70),
                        ),
                        alignment: PlaceholderAlignment.middle,
                      ),
                      TextSpan(text: Utility().text1_fifth),
                      WidgetSpan(
                        child: Text(
                          Utility().appName,
                          style: GoogleFonts.libreFranklin(
                            color: HonooColor.secondary,
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        alignment: PlaceholderAlignment.middle,
                      ),
                      TextSpan(text: Utility().text1_six),
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
                IconButton(
                  icon: SvgPicture.asset(
                    "assets/icons/home.svg",
                    semanticsLabel: 'Home',
                  ),
                  iconSize: 60,
                  tooltip: 'Indietro',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Questo è il corpo della pagina
    final Widget pageBody = Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          Expanded(child: Container()),
          isPhone
              ? Container(
            color: HonooColor.background,
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: content,
          )
              : Opacity(
            opacity: 0.7,
            child: Container(
              color: HonooColor.background,
              constraints: BoxConstraints(maxWidth: maxWidth * 0.5),
              child: content,
            ),
          ),
          Expanded(child: Container()),
        ],
      ),
    );

    // Ritorna il widget con o senza Background
    return isPhone ? pageBody : Background(child: pageBody);
  }

}
