import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Controller/device_controller.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Utility/responsive_layout.dart';
import 'package:honoo/Widgets/background.dart';
import 'package:honoo/Widgets/honoo_app_title.dart';
import 'package:honoo/Widgets/responsive_footer_bar.dart';

class VenceslaoPage extends StatelessWidget {
  const VenceslaoPage({super.key});

  static const String venceslaoCembaloText =
      "Sono nato a Napoli\n"
      "nel 1965.\n\n"
      "Ho vissuto in città diverse\n"
      "e ho lavorato\n"
      "in contesti molto differenti.\n\n"
      "Se dovessi trovare\n"
      "un filo conduttore,\n"
      "credo che lo individuerei\n"
      "nella scrittura,\n\n"
      "che a volte\n"
      "ha assunto la forma\n"
      "dell’immagine,\n\n"
      "a volte\n"
      "della parola scritta,\n\n"
      "a volte\n"
      "della parola detta,\n\n"
      "a minori a rischio,\n"
      "a detenute,\n\n"
      "a studenti\n"
      "di scuole superiori,\n"
      "di Università,\n"
      "di Accademie di Belle Arti,\n\n"
      "a docenti\n"
      "all’interno\n"
      "di corsi di formazione.\n\n"
      "Per tredici anni\n"
      "ho scritto i testi\n"
      "di un programma televisivo\n"
      "per bambini,\n\n"
      "La Melevisione,\n\n"
      "e di tutto ciò\n"
      "che da quel programma\n"
      "è nato:\n\n"
      "canzoni,\n"
      "spettacoli,\n"
      "libri.\n\n"
      "Oggi\n"
      "insegno\n"
      "Teoria e metodo\n"
      "dei mass media\n"
      "all’Accademia di Belle Arti\n"
      "di Napoli.\n\n"
      "Scrivo.\n\n"
      "Alcuni testi\n"
      "sono in fase\n"
      "di pubblicazione,\n\n"
      "altri\n"
      "sono ancora\n"
      "in lavorazione.\n\n"
      "Papà,\n"
      "ma tu mi vuoi bene?\n\n"
      "è il romanzo\n"
      "su cui sto lavorando\n"
      "adesso.\n\n"
      "honoo\n"
      "nasce da qui.\n";

  @override
  Widget build(BuildContext context) {
    final isPhone = DeviceController().isPhone();
    final screenWidth = MediaQuery.of(context).size.width;
    final ResponsiveLayoutMode layoutMode =
        ResponsiveLayout.modeForWidth(screenWidth);
    final double footerIconSize =
        ResponsiveLayout.footerIconSizeForMode(layoutMode);
    final double footerBottomPadding =
        ResponsiveLayout.footerBottomPaddingForMode(layoutMode);
    final double footerGap = ResponsiveLayout.footerGapForMode(layoutMode);
    final double safeBottom = MediaQuery.of(context).viewPadding.bottom;
    final double footerSpacing = footerBottomPadding + safeBottom;
    final double footerTopSpacing = footerSpacing / 2;
    final double footerBottomSpacing = footerSpacing - footerTopSpacing;
    final double footerSidePadding;
    switch (layoutMode) {
      case ResponsiveLayoutMode.mobile:
        footerSidePadding = 16;
        break;
      case ResponsiveLayoutMode.tablet:
        footerSidePadding = 20;
        break;
      case ResponsiveLayoutMode.desktop:
      case ResponsiveLayoutMode.wideDesktop:
      case ResponsiveLayoutMode.largeDesktop:
        footerSidePadding = 24;
        break;
    }
    final double contentWidth;
    if (isPhone) {
      contentWidth = screenWidth;
    } else {
      const double minDesktopWidth = 420.0;
      final double target = screenWidth * 0.45;
      contentWidth = target < minDesktopWidth ? minDesktopWidth : target;
    }

    final TextStyle bodyStyle = GoogleFonts.arvo(
      color: HonooColor.onBackground,
      fontSize: 18,
      fontWeight: FontWeight.w200,
      height: 1.3,
    );

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
                child: Text(
                  venceslaoCembaloText,
                  style: bodyStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          SizedBox(height: footerTopSpacing),
          Padding(
            padding: EdgeInsets.only(left: footerSidePadding),
            child: ResponsiveFooterBar(
              useSafeArea: false,
              bottomPadding: footerBottomSpacing,
              desiredGap: footerGap,
              minGap: 16,
              height: footerIconSize,
              mainAxisAlignment: MainAxisAlignment.start,
              alignment: Alignment.centerLeft,
              actions: [
                ResponsiveFooterAction(
                  asset: "assets/icons/home.svg",
                  semanticsLabel: 'Home',
                  size: footerIconSize,
                  tooltip: 'Home',
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final Widget pageBody = Scaffold(
      backgroundColor: HonooColor.background,
      body: Row(
        children: [
          Expanded(child: Container()),
          Align(
            alignment: Alignment.center,
            child: Container(
              color: HonooColor.background.withOpacity(isPhone ? 1 : 0.7),
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: content,
            ),
          ),
          Expanded(child: Container()),
        ],
      ),
    );

    return isPhone ? pageBody : Background(child: pageBody);
  }
}
