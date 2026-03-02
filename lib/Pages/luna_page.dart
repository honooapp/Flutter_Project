import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Controller/device_controller.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Utility/responsive_layout.dart';
import 'package:honoo/Widgets/honoo_app_title.dart';
import 'package:honoo/Widgets/responsive_footer_bar.dart';

import 'home_page.dart';
import 'placeholder_page.dart';

class LunaPage extends StatelessWidget {
  const LunaPage({super.key});

  static const String lunaText =
      "Cosa c’è\n"
      "oggi\n"
      "sulla Luna?\n\n"
      "Qualcosa\n"
      "che ti incuriosisce?\n\n"
      "Ti basta guardare\n"
      "da lontano?\n\n"
      "O vorresti fare\n"
      "qualcosa di più?\n\n"
      "O molto di più?\n\n"
      "A lezione dico sempre\n"
      "che considero\n"
      "honoo e hinoo\n"
      "non come\n"
      "prodotti finiti,\n"
      "ma come momenti\n"
      "di un processo di scrittura,\n"
      "articolato\n"
      "come viaggio\n"
      "di esplorazione\n"
      "di un’Isola.\n\n"
      "Però\n"
      "qui\n"
      "non sono\n"
      "a lezione.\n\n"
      "E poi ci sono\n"
      "i momenti\n"
      "in cui esagero,\n"
      "come adesso,\n"
      "e allora dico\n"
      "che la Luna di honoo\n"
      "potrebbe essere\n"
      "l’app ideata,\n"
      "per gioco,\n"
      "da Dante\n"
      "o da Guido Cavalcanti,\n"
      "se l’incantesimo del Mago\n"
      "li avesse fatti riapparire\n"
      "dalle nostre parti,\n"
      "in questi giorni.\n";

  @override
  Widget build(BuildContext context) {
    final bool isPhone = DeviceController().isPhone();
    final double deviceWidth = MediaQuery.of(context).size.width;
    final ResponsiveLayoutMode layoutMode =
        ResponsiveLayout.modeForWidth(deviceWidth);
    final double footerIconSize =
        ResponsiveLayout.footerIconSizeForMode(layoutMode);
    final double footerBottomPadding =
        ResponsiveLayout.footerBottomPaddingForMode(layoutMode);
    final double safeBottom = MediaQuery.of(context).viewPadding.bottom;
    final double footerSpacing = footerBottomPadding + safeBottom;
    final double footerTopSpacing = footerSpacing / 2;
    final double footerBottomSpacing = footerSpacing - footerTopSpacing;

    final TextStyle baseTextStyle = GoogleFonts.arvo(
      color: HonooColor.onBackground,
      fontSize: 18,
      fontWeight: FontWeight.w200,
      height: 1.3,
    );

    return Scaffold(
      backgroundColor: HonooColor.background,
      body: Row(
        children: [
          const Spacer(),
          Container(
            constraints: BoxConstraints(
              maxWidth: isPhone ? deviceWidth : deviceWidth * 0.5,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    height: 52,
                    child: Center(
                      child: HonooAppTitle(
                        onTap: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const PlaceholderPage()),
                            (route) => false,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 5.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      lunaText,
                      style: baseTextStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(height: footerTopSpacing),
                  ResponsiveFooterBar(
                    useSafeArea: false,
                    bottomPadding: footerBottomSpacing,
                    desiredGap: ResponsiveLayout.footerGapForMode(layoutMode),
                    minGap: 16,
                    height: footerIconSize,
                    mainAxisAlignment: MainAxisAlignment.start,
                    alignment: Alignment.centerLeft,
                    actions: [
                      ResponsiveFooterAction(
                        asset: "assets/icons/home.svg",
                        semanticsLabel: 'Home',
                        size: footerIconSize,
                        splashRadius: 25,
                        tooltip: 'Home',
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const HomePage()),
                            (route) => false,
                          );
                        },
                      ),
                    ],
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

