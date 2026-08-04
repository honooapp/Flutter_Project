import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Controller/device_controller.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Utility/responsive_layout.dart';
import 'package:honoo/Widgets/honoo_app_title.dart';
import 'package:honoo/Widgets/responsive_footer_bar.dart';
import 'package:honoo/Widgets/background.dart';

import 'home_page.dart';

class LaboratoriNoiELoroPage extends StatelessWidget {
  const LaboratoriNoiELoroPage({super.key});

  static const String laboratoriText =
      "Noi e loro\n\n"
      "è un laboratorio teatrale\n"
      "progettato\n"
      "come un viaggio\n"
      "di esplorazione\n"
      "sull’identità,\n"
      "la diversità,\n"
      "il rispetto\n"
      "e la cooperazione\n\n"
      "“Noi” siamo noi,\n"
      "che abitiamo qui,\n"
      "da noi\n\n"
      "Facciamo\n"
      "le cose\n"
      "che facciamo noi,\n"
      "mangiamo\n"
      "le cose nostre\n"
      "e abbiamo\n"
      "le nostre tradizioni\n"
      "e le nostre abitudini\n\n"
      "“Loro” sono loro,\n"
      "che sono diversi da noi\n\n"
      "Non li conosciamo bene,\n"
      "ma sappiamo\n"
      "che non sono come noi\n\n"
      "In un posto lontano,\n"
      "molto lontano da noi,\n"
      "al di là del mare,\n"
      "ci sono loro\n\n"
      "A questo progetto\n"
      "partecipano studenti\n"
      "di due scuole superiori\n\n"
      "Una scuola è a\n"
      "Via dell’Archeologia 58,\n"
      "Aversa (CE), Italia\n\n"
      "L’altra è a\n"
      "FGV7+PQP,\n"
      "Māhina,\n"
      "Polinesia francese\n\n"
      "Sì,\n"
      "honoo ha partecipato\n"
      "a un Bando Siae\n"
      "E ha vinto\n";

  @override
  Widget build(BuildContext context) {
    final bool isPhone = DeviceController().isPhone();
    final double screenWidth = MediaQuery.of(context).size.width;
    final ResponsiveLayoutMode layoutMode = ResponsiveLayout.modeForWidth(
      screenWidth,
    );
    final double footerIconSize = ResponsiveLayout.footerIconSizeForMode(
      layoutMode,
    );
    final double footerBottomPadding =
        ResponsiveLayout.footerBottomPaddingForMode(layoutMode);
    final double safeBottom = MediaQuery.of(context).viewPadding.bottom;
    final double footerSpacing = footerBottomPadding + safeBottom;
    final double footerTopSpacing = footerSpacing / 2;
    final double footerBottomSpacing = footerSpacing - footerTopSpacing;
    final double footerSidePadding = () {
      switch (layoutMode) {
        case ResponsiveLayoutMode.mobile:
          return 16.0;
        case ResponsiveLayoutMode.tablet:
          return 20.0;
        case ResponsiveLayoutMode.desktop:
        case ResponsiveLayoutMode.wideDesktop:
        case ResponsiveLayoutMode.largeDesktop:
          return 24.0;
      }
    }();

    final double contentWidth = isPhone
        ? screenWidth
        : () {
            const double minDesktopWidth = 420.0;
            final double target = screenWidth * 0.4;
            return target < minDesktopWidth ? minDesktopWidth : target;
          }();

    final TextStyle baseTextStyle = GoogleFonts.arvo(
      color: HonooColor.onBackground,
      fontSize: 18,
      fontWeight: FontWeight.w200,
      height: 1.3,
    );

    final Widget content = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: 52, child: Center(child: HonooAppTitle())),
          Expanded(
            child: SingleChildScrollView(
              child: SizedBox(
                width: contentWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    laboratoriText,
                    style: baseTextStyle,
                    textAlign: TextAlign.center,
                  ),
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

    final Widget pageBody = Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          Expanded(child: Container()),
          Align(
            alignment: Alignment.center,
            child: Container(
              color: HonooColor.background.withValues(alpha: isPhone ? 1 : 0.7),
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
