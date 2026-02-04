import 'package:flutter/material.dart';
import 'package:honoo/Controller/device_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Widgets/responsive_footer_bar.dart';
import 'package:honoo/Utility/responsive_layout.dart';

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
  WidgetSpan _inlineIcon(
    String asset, {
    required double iconHeight,
    double topPadding = 3,
    double bottomPadding = 3,
  }) {
    return WidgetSpan(
      child: SizedBox(
        height: iconHeight + topPadding + bottomPadding,
        child: Padding(
          padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
          child: Image.asset(asset, height: iconHeight),
        ),
      ),
      alignment: PlaceholderAlignment.middle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = DeviceController().isPhone();
    final screenWidth = MediaQuery.of(context).size.width;
    final ResponsiveLayoutMode layoutMode =
        ResponsiveLayout.modeForWidth(screenWidth);
    const String performanceLine = 'performance';
    const String laboratoriLine = 'laboratori teatrali';
    const String esplorazioniLine = 'esplorazioni lunari';
    const String festeLine = 'feste';
    const String viaggiLine = "viaggi sull'Isola delle Storie.";
    const String venceslaoLine = 'Venceslao Cembalo\n';
    final String text1First = Utility().text1First;
    const String performanceMarker = 'che ci siamo visti\n\n';
    final String text1Fourth = Utility().text1Fourth;
    final int performanceMarkerIndex = text1Fourth.indexOf(performanceMarker);
    String textBeforePerformanceMarker = text1Fourth;
    String textAfterPerformanceMarker = '';
    if (performanceMarkerIndex != -1) {
      textBeforePerformanceMarker =
          text1Fourth.substring(0, performanceMarkerIndex + performanceMarker.length);
      textAfterPerformanceMarker =
          text1Fourth.substring(performanceMarkerIndex + performanceMarker.length);
    }
    final String text1Fifth = Utility().text1Fifth;
    final int venceslaoIndex = text1Fifth.indexOf(venceslaoLine);
    String textBeforeVenceslao = text1Fifth;
    String textAfterVenceslao = '';
    if (venceslaoIndex != -1) {
      textBeforeVenceslao = text1Fifth.substring(0, venceslaoIndex);
      textAfterVenceslao = text1Fifth.substring(
        venceslaoIndex + venceslaoLine.length,
      );
    }
    final double footerIconSize =
        ResponsiveLayout.footerIconSizeForMode(layoutMode);
    final double footerBottomPadding =
        ResponsiveLayout.footerBottomPaddingForMode(layoutMode);
    final double footerGap = ResponsiveLayout.footerGapForMode(layoutMode);
    final double safeBottom = MediaQuery.of(context).viewPadding.bottom;
    final double footerSpacing = footerBottomPadding + safeBottom;
    final double footerTopSpacing = footerSpacing / 2;
    final double footerBottomSpacing = footerSpacing - footerTopSpacing;
    final double inlineIconHeight;
    switch (layoutMode) {
      case ResponsiveLayoutMode.mobile:
        inlineIconHeight = 60;
        break;
      case ResponsiveLayoutMode.tablet:
        inlineIconHeight = 66;
        break;
      case ResponsiveLayoutMode.desktop:
      case ResponsiveLayoutMode.wideDesktop:
      case ResponsiveLayoutMode.largeDesktop:
        inlineIconHeight = 70;
        break;
    }
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
                      TextSpan(text: text1First),
                      const TextSpan(text: '$performanceLine\n'),
                      _inlineIcon(
                        "assets/icons/performance.png",
                        iconHeight: inlineIconHeight,
                      ),
                      const TextSpan(text: '\n'),
                      const TextSpan(text: '$laboratoriLine\n'),
                      _inlineIcon(
                        "assets/icons/laboratori_teatrali.png",
                        iconHeight: inlineIconHeight,
                      ),
                      const TextSpan(text: '\n'),
                      const TextSpan(text: '$esplorazioniLine\n'),
                      _inlineIcon(
                        "assets/icons/luna.png",
                        iconHeight: inlineIconHeight,
                      ),
                      const TextSpan(text: '\n'),
                      const TextSpan(text: '$festeLine\n'),
                      _inlineIcon(
                        "assets/icons/feste.png",
                        iconHeight: inlineIconHeight,
                      ),
                      const TextSpan(text: '\n'),
                      const TextSpan(text: '$viaggiLine\n'),
                      _inlineIcon(
                        "assets/icons/isola.png",
                        iconHeight: inlineIconHeight,
                      ),
                      TextSpan(text: textBeforePerformanceMarker),
                      if (performanceMarkerIndex != -1)
                        _inlineIcon(
                          "assets/icons/performance.png",
                          iconHeight: inlineIconHeight,
                        ),
                      TextSpan(text: textAfterPerformanceMarker),
                      TextSpan(text: textBeforeVenceslao),
                      const TextSpan(text: venceslaoLine),
                      _inlineIcon(
                        "assets/icons/venceslao.png",
                        iconHeight: inlineIconHeight,
                      ),
                      const TextSpan(text: '\n'),
                      TextSpan(text: textAfterVenceslao),
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
