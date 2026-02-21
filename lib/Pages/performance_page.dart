import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Controller/device_controller.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Utility/responsive_layout.dart';
import 'package:honoo/Widgets/background.dart';
import 'package:honoo/Widgets/honoo_app_title.dart';
import 'package:honoo/Widgets/responsive_footer_bar.dart';

class PerformancePage extends StatelessWidget {
  const PerformancePage({super.key});


  static const String performanceText =
      "Venceslao Cembalo,\n"
      "Antonio Della Guardia\n"
      "e Sira Sebastianelli\n"
      "hanno presentato\n"
      "per la prima volta\n"
      "Isola delle Storie\n"
      "a Roma,\n"
      "nella Galleria\n"
      "Spazio Taverna.\n\n"
      "Da Roma\n"
      "Isola delle Storie\n"
      "è arrivata\n"
      "Lunedì 13 maggio 2024,\n"
      "dalle 18.00 alle 21.00,\n"
      "alla Triennale di Milano,\n"
      "a Casa Lana,\n"
      "progettata da Ettore Sottsass.\n\n"
      "Sì,\n"
      "honoo è stato invitato\n"
      "alla Triennale.\n";

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
                  performanceText,
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
