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
  @override
  Widget build(BuildContext context) {
    final isPhone = DeviceController().isPhone();
    final screenWidth = MediaQuery.of(context).size.width;
    final ResponsiveLayoutMode layoutMode =
        ResponsiveLayout.modeForWidth(screenWidth);
    const String performanceLine = 'performance\n';
    const String laboratoriLine = 'e laboratori teatrali\n';
    const String venceslaoLine = 'Venceslao Cembalo\n';
    final String text1First = Utility().text1First;
    final int performanceIndex = text1First.indexOf(performanceLine);
    final int laboratoriIndex = text1First.indexOf(laboratoriLine);
    String textBeforePerformance = text1First;
    String textBetweenPerformance = '';
    String textAfterLaboratori = '';
    if (performanceIndex != -1 &&
        laboratoriIndex != -1 &&
        performanceIndex < laboratoriIndex) {
      textBeforePerformance = text1First.substring(0, performanceIndex);
      textBetweenPerformance = text1First.substring(
        performanceIndex + performanceLine.length,
        laboratoriIndex,
      );
      textAfterLaboratori =
          text1First.substring(laboratoriIndex + laboratoriLine.length);
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
                      TextSpan(text: textBeforePerformance),
                      const TextSpan(text: performanceLine),
                      WidgetSpan(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Image.asset("assets/icons/performance.png",
                              height: 70),
                        ),
                        alignment: PlaceholderAlignment.middle,
                      ),
                      const TextSpan(text: '\n'),
                      TextSpan(text: textBetweenPerformance),
                      const TextSpan(text: laboratoriLine),
                      WidgetSpan(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Image.asset(
                            "assets/icons/laboratori_teatrali.png",
                            height: 70,
                          ),
                        ),
                        alignment: PlaceholderAlignment.middle,
                      ),
                      TextSpan(text: textAfterLaboratori),
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
                      TextSpan(text: textBeforeVenceslao),
                      const TextSpan(text: venceslaoLine),
                      WidgetSpan(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Image.asset(
                            "assets/icons/venceslao.png",
                            height: 70,
                          ),
                        ),
                        alignment: PlaceholderAlignment.middle,
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
