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
  // Regola qui gli spazi sopra/sotto le icone (valori in pixel).
  static const double _performanceTopSpacing = 5;
  static const double _performanceBottomSpacing = 30;
  static const double _laboratoriTopSpacing = 5;
  static const double _laboratoriBottomSpacing = 30;
  static const double _lunaTopSpacing = -5;
  static const double _lunaBottomSpacing = 30;
  static const double _festeTopSpacing = 5;
  static const double _festeBottomSpacing = 30;
  static const double _isolaTopSpacing = -5;
  static const double _isolaBottomSpacing = 20;
  static const double _performanceSecondTopSpacing = 15;
  static const double _performanceSecondBottomSpacing = 15;
  static const double _venceslaoTopSpacing = 15;
  static const double _venceslaoBottomSpacing = 15;
  static const double _honooTopSpacing = 15;
  static const double _honooBottomSpacing = 15;

  List<Widget> _iconBlockWithSpacing(
    String asset,
    double size, {
    double topSpacing = 0,
    double bottomSpacing = 0,
  }) {
    return [
      if (topSpacing > 0) SizedBox(height: topSpacing),
      Image.asset(asset, height: size),
      if (bottomSpacing > 0) SizedBox(height: bottomSpacing),
    ];
  }

  Widget _textBlock(String text, TextStyle style, {double? height}) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Text(
      text,
      style: height == null ? style : style.copyWith(height: height),
      textAlign: TextAlign.center,
    );
  }

  String _trimInlineText(String text) {
    return text
        .replaceAll(RegExp(r'^\n+'), '')
        .replaceAll(RegExp(r'\n+$'), '');
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
    const String viaggiLine = "viaggi sull'Isola delle Storie";
    const String venceslaoLine = 'Venceslao Cembalo';
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
    final String textBeforePerformanceMarkerDisplay =
        _trimInlineText(textBeforePerformanceMarker);
    final String textAfterPerformanceMarkerDisplay =
        _trimInlineText(textAfterPerformanceMarker);
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
    final String textBeforeVenceslaoDisplay = _trimInlineText(textBeforeVenceslao);
    final String textAfterVenceslaoDisplay = _trimInlineText(textAfterVenceslao);
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
    final TextStyle baseTextStyle = GoogleFonts.arvo(
      color: HonooColor.onBackground,
      fontSize: 18,
      fontWeight: FontWeight.w200,
      height: 1.3,
    );

    final TextStyle titleStyle = GoogleFonts.libreFranklin(
      color: HonooColor.secondary,
      fontSize: 28,
      fontWeight: FontWeight.w600,
    );

    // Sequenza dei testi e delle icone in ordine di apparizione.
    final List<Widget> blocks = [
      _textBlock('${_trimInlineText(text1First)}\n', baseTextStyle),
      _textBlock(performanceLine, baseTextStyle),
      ..._iconBlockWithSpacing(
        "assets/icons/performance.png",
        inlineIconHeight,
        topSpacing: _performanceTopSpacing,
        bottomSpacing: _performanceBottomSpacing,
      ),
      _textBlock(laboratoriLine, baseTextStyle),
      ..._iconBlockWithSpacing(
        "assets/icons/laboratori_teatrali.png",
        inlineIconHeight,
        topSpacing: _laboratoriTopSpacing,
        bottomSpacing: _laboratoriBottomSpacing,
      ),
      _textBlock(esplorazioniLine, baseTextStyle, height: 0.9),
      ..._iconBlockWithSpacing(
        "assets/icons/luna.png",
        inlineIconHeight,
        topSpacing: _lunaTopSpacing,
        bottomSpacing: _lunaBottomSpacing,
      ),
      _textBlock(festeLine, baseTextStyle),
      ..._iconBlockWithSpacing(
        "assets/icons/feste.png",
        inlineIconHeight,
        topSpacing: _festeTopSpacing,
        bottomSpacing: _festeBottomSpacing,
      ),
      _textBlock(viaggiLine, baseTextStyle, height: 0.9),
      ..._iconBlockWithSpacing(
        "assets/icons/isola.png",
        inlineIconHeight,
        topSpacing: _isolaTopSpacing,
        bottomSpacing: _isolaBottomSpacing,
      ),
      _textBlock(textBeforePerformanceMarkerDisplay, baseTextStyle, height: 0.9),
      if (performanceMarkerIndex != -1)
        ..._iconBlockWithSpacing(
          "assets/icons/performance.png",
          inlineIconHeight,
          topSpacing: _performanceSecondTopSpacing,
          bottomSpacing: _performanceSecondBottomSpacing,
        ),
      _textBlock(textAfterPerformanceMarkerDisplay, baseTextStyle),
      _textBlock(textBeforeVenceslaoDisplay, baseTextStyle),
      _textBlock(venceslaoLine, baseTextStyle, height: 0.9),
      ..._iconBlockWithSpacing(
        "assets/icons/venceslao.png",
        inlineIconHeight,
        topSpacing: _venceslaoTopSpacing,
        bottomSpacing: _venceslaoBottomSpacing,
      ),
      _textBlock(textAfterVenceslaoDisplay, baseTextStyle),
      SizedBox(height: _honooTopSpacing),
      _textBlock(Utility().appName, titleStyle),
      SizedBox(height: _honooBottomSpacing),
      _textBlock(_trimInlineText(Utility().text1Six), baseTextStyle),
    ];

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: blocks,
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
