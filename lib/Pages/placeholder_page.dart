import 'package:flutter/material.dart';
import 'package:honoo/Controller/device_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../Utility/honoo_colors.dart';
import '../Utility/utility.dart';
import '../Widgets/background.dart';
import '../Widgets/honoo_app_title.dart';
import 'home_page.dart';

class PlaceholderPage extends StatefulWidget {
  const PlaceholderPage({super.key});

  @override
  State<PlaceholderPage> createState() => _PlaceholderPageState();
}

class _PlaceholderPageState extends State<PlaceholderPage> {
  @override
  Widget build(BuildContext context) {
    final isPhone = DeviceController().isPhone();
    final screenWidth = MediaQuery.of(context).size.width;
    final double contentWidth;
    if (isPhone) {
      contentWidth = screenWidth;
    } else {
      const double minDesktopWidth = 420.0;
      final double target = screenWidth * 0.4; // 20% più stretto rispetto al 50%
      contentWidth = target < minDesktopWidth ? minDesktopWidth : target;
    }

    // Contenuto principale, usato in entrambi i layout
    final Widget content = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(
            height: 52,
            child: Center(
              child: HonooAppTitle(),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: SizedBox(
                width: contentWidth,
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.arvo(
                      color: HonooColor.onBackground,
                      fontSize: 18,
                      fontWeight: FontWeight.w200,
                    ),
                    children: [
                      TextSpan(text: Utility().text1First),
                      WidgetSpan(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Image.asset("assets/icons/performance.png",
                              height: 70),
                        ),
                        alignment: PlaceholderAlignment.middle,
                      ),
                      TextSpan(text: Utility().text1Second),
                      WidgetSpan(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child:
                              Image.asset("assets/icons/luna.png", height: 70),
                        ),
                        alignment: PlaceholderAlignment.middle,
                      ),
                      TextSpan(text: Utility().text1Third),
                      WidgetSpan(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child:
                              Image.asset("assets/icons/isola.png", height: 70),
                        ),
                        alignment: PlaceholderAlignment.middle,
                      ),
                      TextSpan(text: Utility().text1Fourth),
                      WidgetSpan(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Image.asset("assets/icons/performance.png",
                              height: 70),
                        ),
                        alignment: PlaceholderAlignment.middle,
                      ),
                      TextSpan(text: Utility().text1Fifth),
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
                      TextSpan(text: Utility().text1Six),
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
                  tooltip: 'Home',
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomePage()),
                      (route) => false,
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
          Align(
            alignment: Alignment.center,
            child: Container(
              color: HonooColor.background.withOpacity(isPhone ? 1 : 0.7),
              constraints: BoxConstraints(
                maxWidth: contentWidth,
              ),
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
