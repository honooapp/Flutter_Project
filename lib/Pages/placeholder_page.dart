import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:honoo/Controller/device_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Widgets/responsive_footer_bar.dart';
import 'package:honoo/Utility/responsive_layout.dart';

import '../Utility/honoo_colors.dart';
import '../Utility/utility.dart';
import '../Widgets/background.dart';
import '../Widgets/honoo_app_title.dart';
import 'package:honoo/Utility/formatted_text.dart';
import 'home_page.dart';
import 'performance_page.dart';
import 'venceslao_page.dart';
import 'feste_page.dart';
import 'luna_page.dart';
import 'viaggi_isola_page.dart';
import 'laboratori_siae_page.dart';
import 'podcast_dirette_page.dart';
import 'libri_page.dart';
import 'la_banda_page.dart';
import 'regia_agenti_page.dart';
import 'bando_honoo_francolise_page.dart';
import 'storiestorie_page.dart';

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
  static const double _lunaIconSizeIncrease = 15;
  static const double _lunaIconVerticalOffset = -2;
  static const double _festeTopSpacing = 5;
  static const double _festeBottomSpacing = 30;
  static const double _festeIconSizeIncrease = 6;
  static const double _isolaTopSpacing = -5;
  static const double _isolaBottomSpacing = 30;
  static const double _podcastTopSpacing = 5;
  static const double _podcastBottomSpacing = 30;
  static const double _performanceSecondTopSpacing = 15;
  static const double _performanceSecondBottomSpacing = 15;
  static const double _venceslaoTopSpacing = 15;
  static const double _venceslaoBottomSpacing = 15;
  static const double _honooTopSpacing = 15;
  static const double _honooBottomSpacing = 15;
  static const double _libriTopSpacing = 5;
  static const double _libriBottomSpacing = 30;
  static const double _storiestorieTopSpacing = 5;
  static const double _storiestorieBottomSpacing = 30;
  static const double _laBandaTopSpacing = 5;
  static const double _laBandaBottomSpacing = 30;
  static const double _bandoFrancoliseTopSpacing = 5;
  static const double _bandoFrancoliseBottomSpacing = 30;
  static const double _regiaAgentiTopSpacing = 18 * 1.3;
  static const double _regiaAgentiBottomSpacing = 30;
  static const double _regiaAgentiIconSizeReduction = 15;
  static const double _regiaAgentiIconVerticalOffset = -2;
  static const Color _linkIconColor = Color.fromRGBO(183, 183, 206, 1);

  List<Widget> _iconBlockWithSpacing(
    String asset,
    double size, {
    double topSpacing = 0,
    double bottomSpacing = 0,
    VoidCallback? onTap,
    Key? bottomSpacingKey,
    Key? transformKey,
    double verticalOffset = 0,
  }) {
    return [
      if (topSpacing > 0) SizedBox(height: topSpacing),
      GestureDetector(
        onTap: onTap,
        child: Transform.translate(
          key: transformKey,
          offset: Offset(0, verticalOffset),
          child: Image.asset(asset, height: size),
        ),
      ),
      if (bottomSpacing > 0)
        SizedBox(key: bottomSpacingKey, height: bottomSpacing),
    ];
  }

  List<Widget> _materialIconBlockWithSpacing(
    IconData icon,
    double size, {
    double topSpacing = 0,
    double bottomSpacing = 0,
    VoidCallback? onTap,
    Color? color,
    Key? iconKey,
  }) {
    return [
      if (topSpacing > 0) SizedBox(height: topSpacing),
      GestureDetector(
        onTap: onTap,
        child: Icon(
          icon,
          key: iconKey,
          size: size,
          color: color ?? HonooColor.onBackground,
        ),
      ),
      if (bottomSpacing > 0) SizedBox(height: bottomSpacing),
    ];
  }

  List<Widget> _svgIconBlockWithSpacing(
    String asset,
    double size, {
    double topSpacing = 0,
    double bottomSpacing = 0,
    VoidCallback? onTap,
    Color? color,
    Key? iconKey,
    Key? topSpacingKey,
    Key? bottomSpacingKey,
    Key? transformKey,
    double verticalOffset = 0,
  }) {
    return [
      if (topSpacing > 0) SizedBox(key: topSpacingKey, height: topSpacing),
      GestureDetector(
        onTap: onTap,
        child: Transform.translate(
          key: transformKey,
          offset: Offset(0, verticalOffset),
          child: SvgPicture.asset(
            key: iconKey,
            asset,
            height: size,
            colorFilter: ColorFilter.mode(
              color ?? HonooColor.onBackground,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
      if (bottomSpacing > 0)
        SizedBox(key: bottomSpacingKey, height: bottomSpacing),
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

  Widget _linkTextBlock(
    BuildContext context,
    String text,
    TextStyle style, {
    double? height,
    VoidCallback? onTap,
  }) {
    final linkStyle = (height == null ? style : style.copyWith(height: height))
        .copyWith(
          decoration: TextDecoration.underline,
          decorationColor: style.color,
          decorationThickness: 3.0,
        );
    return InkWell(
      onTap:
          onTap ??
          () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Sezione in arrivo')));
          },
      child: Text(text, style: linkStyle, textAlign: TextAlign.center),
    );
  }

  Widget _venceslaoLink(
    BuildContext context,
    String text,
    TextStyle style, {
    double? height,
  }) {
    return InkWell(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const VenceslaoPage()));
      },
      child: Text(
        text,
        style: (height == null ? style : style.copyWith(height: height))
            .copyWith(
              decoration: TextDecoration.underline,
              decorationColor: style.color,
              decorationThickness: 3.0,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _trimInlineText(String text) {
    return text.replaceAll(RegExp(r'^\n+'), '').replaceAll(RegExp(r'\n+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = DeviceController().isPhone();
    final screenWidth = MediaQuery.of(context).size.width;
    final ResponsiveLayoutMode layoutMode = ResponsiveLayout.modeForWidth(
      screenWidth,
    );
    const String performanceLine = 'Performance';
    const String laboratoriLine = 'Laboratori teatrali';
    const String esplorazioniLine = 'Esplorazioni lunari';
    const String festeLine = 'Feste';
    const String viaggiLine = "Viaggi sull'Isola delle Storie";
    const String podcastLine = 'Podcast e dirette';
    const String libriLine = 'Libri';
    const String storiestorieLine = 'Storiestorie.it';
    const String laBandaLine = 'La Banda';
    const String bandoFrancoliseLine = 'Bando honoo\nper Francolise';
    const String regiaAgentiLine = 'Regia degli Agenti';
    const String venceslaoLine = 'Venceslao Cembalo';
    final String text1First = Utility().text1First;
    const String performanceMarker = 'che ci siamo visti\n\n';
    final String text1Fourth = Utility().text1Fourth;
    final int performanceMarkerIndex = text1Fourth.indexOf(performanceMarker);
    String textBeforePerformanceMarker = text1Fourth;
    String textAfterPerformanceMarker = '';
    if (performanceMarkerIndex != -1) {
      textBeforePerformanceMarker = text1Fourth.substring(
        0,
        performanceMarkerIndex + performanceMarker.length,
      );
      textAfterPerformanceMarker = text1Fourth.substring(
        performanceMarkerIndex + performanceMarker.length,
      );
    }
    final String textBeforePerformanceMarkerDisplay = _trimInlineText(
      textBeforePerformanceMarker,
    );
    final String textAfterPerformanceMarkerDisplay = _trimInlineText(
      textAfterPerformanceMarker,
    );
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
    final String textBeforeVenceslaoDisplay = _trimInlineText(
      textBeforeVenceslao,
    );
    final String textAfterVenceslaoDisplay = _trimInlineText(
      textAfterVenceslao,
    );
    final double footerIconSize = ResponsiveLayout.footerIconSizeForMode(
      layoutMode,
    );
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
      final double target =
          screenWidth * 0.4; // 20% più stretto rispetto al 50%
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
      _linkTextBlock(
        context,
        performanceLine,
        baseTextStyle,
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const PerformancePage()));
        },
      ),
      ..._iconBlockWithSpacing(
        "assets/icons/performance.png",
        inlineIconHeight,
        topSpacing: _performanceTopSpacing,
        bottomSpacing: _performanceBottomSpacing,
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const PerformancePage()));
        },
      ),
      _linkTextBlock(
        context,
        laboratoriLine,
        baseTextStyle,
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const LaboratoriSiaePage()));
        },
      ),
      ..._iconBlockWithSpacing(
        "assets/icons/laboratori_teatrali.png",
        inlineIconHeight,
        topSpacing: _laboratoriTopSpacing,
        bottomSpacing: _laboratoriBottomSpacing,
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const LaboratoriSiaePage()));
        },
      ),
      _linkTextBlock(
        context,
        esplorazioniLine,
        baseTextStyle,
        height: 0.9,
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const LunaPage()));
        },
      ),
      ..._iconBlockWithSpacing(
        "assets/icons/luna.png",
        inlineIconHeight + _lunaIconSizeIncrease,
        topSpacing: _lunaTopSpacing,
        bottomSpacing: _lunaBottomSpacing,
        transformKey: const Key('luna_icon_transform'),
        verticalOffset: _lunaIconVerticalOffset,
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const LunaPage()));
        },
      ),
      _linkTextBlock(
        context,
        festeLine,
        baseTextStyle,
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const FestePage()));
        },
      ),
      ..._iconBlockWithSpacing(
        "assets/icons/feste.png",
        inlineIconHeight + _festeIconSizeIncrease,
        topSpacing: _festeTopSpacing,
        bottomSpacing: _festeBottomSpacing,
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const FestePage()));
        },
      ),
      _linkTextBlock(
        context,
        viaggiLine,
        baseTextStyle,
        height: 0.9,
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ViaggiIsolaPage()));
        },
      ),
      ..._iconBlockWithSpacing(
        "assets/icons/isola.png",
        inlineIconHeight,
        topSpacing: _isolaTopSpacing,
        bottomSpacing: _isolaBottomSpacing,
        bottomSpacingKey: const Key('isola_icon_bottom_spacing'),
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ViaggiIsolaPage()));
        },
      ),
      _linkTextBlock(
        context,
        laBandaLine,
        baseTextStyle,
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const LaBandaPage()));
        },
      ),
      ..._materialIconBlockWithSpacing(
        Icons.groups,
        inlineIconHeight,
        topSpacing: _laBandaTopSpacing,
        bottomSpacing: _laBandaBottomSpacing,
        color: _linkIconColor,
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const LaBandaPage()));
        },
      ),
      _linkTextBlock(
        context,
        bandoFrancoliseLine,
        baseTextStyle,
        height: 0.9,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BandoHonooFrancolisePage()),
          );
        },
      ),
      ..._materialIconBlockWithSpacing(
        Icons.castle,
        inlineIconHeight,
        topSpacing: _bandoFrancoliseTopSpacing,
        bottomSpacing: _bandoFrancoliseBottomSpacing,
        color: _linkIconColor,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BandoHonooFrancolisePage()),
          );
        },
      ),
      _linkTextBlock(
        context,
        regiaAgentiLine,
        baseTextStyle,
        height: 0.9,
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const RegiaAgentiPage()));
        },
      ),
      ..._svgIconBlockWithSpacing(
        'assets/icons/ai.svg',
        inlineIconHeight - _regiaAgentiIconSizeReduction,
        topSpacing: _regiaAgentiTopSpacing,
        bottomSpacing: _regiaAgentiBottomSpacing,
        color: _linkIconColor,
        iconKey: const Key('regia_agenti_icon'),
        topSpacingKey: const Key('regia_agenti_icon_top_spacing'),
        bottomSpacingKey: const Key('regia_agenti_icon_bottom_spacing'),
        transformKey: const Key('regia_agenti_icon_transform'),
        verticalOffset: _regiaAgentiIconVerticalOffset,
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const RegiaAgentiPage()));
        },
      ),
      _linkTextBlock(
        context,
        podcastLine,
        baseTextStyle,
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const PodcastDirettePage()));
        },
      ),
      ..._materialIconBlockWithSpacing(
        Icons.mic,
        inlineIconHeight,
        topSpacing: _podcastTopSpacing,
        bottomSpacing: _podcastBottomSpacing,
        color: _linkIconColor,
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const PodcastDirettePage()));
        },
      ),
      _linkTextBlock(
        context,
        libriLine,
        baseTextStyle,
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const LibriPage()));
        },
      ),
      ..._materialIconBlockWithSpacing(
        Icons.book,
        inlineIconHeight,
        topSpacing: _libriTopSpacing,
        bottomSpacing: _libriBottomSpacing,
        color: _linkIconColor,
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const LibriPage()));
        },
      ),
      _linkTextBlock(
        context,
        storiestorieLine,
        baseTextStyle,
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const StoriestoriePage()));
        },
      ),
      ..._materialIconBlockWithSpacing(
        Icons.public,
        inlineIconHeight,
        topSpacing: _storiestorieTopSpacing,
        bottomSpacing: _storiestorieBottomSpacing,
        color: _linkIconColor,
        iconKey: const Key('storiestorie_icon'),
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const StoriestoriePage()));
        },
      ),
      _textBlock(textBeforePerformanceMarkerDisplay, baseTextStyle),
      if (performanceMarkerIndex != -1)
        ..._iconBlockWithSpacing(
          "assets/icons/performance.png",
          inlineIconHeight,
          topSpacing: _performanceSecondTopSpacing,
          bottomSpacing: _performanceSecondBottomSpacing,
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PerformancePage()));
          },
        ),
      _textBlock(textAfterPerformanceMarkerDisplay, baseTextStyle),
      _textBlock(textBeforeVenceslaoDisplay, baseTextStyle),
      _venceslaoLink(context, venceslaoLine, baseTextStyle, height: 0.9),
      ..._iconBlockWithSpacing(
        "assets/icons/venceslao.png",
        inlineIconHeight,
        topSpacing: _venceslaoTopSpacing,
        bottomSpacing: _venceslaoBottomSpacing,
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const VenceslaoPage()));
        },
      ),
      _textBlock(textAfterVenceslaoDisplay, baseTextStyle),
      const SizedBox(height: _honooTopSpacing),
      _textBlock(Utility().appName, titleStyle),
      const SizedBox(height: _honooBottomSpacing),
      _textBlock(_trimInlineText(Utility().text1Six), baseTextStyle),
      // Usa FormattedText per supportare hyperlink cliccabili nel testo di sostegno
      FormattedText(
        inputText: Utility().sostieniText,
        color: HonooColor.onBackground,
        fontSize: 18,
        fontWeight: FontWeight.w200,
        linkFontWeight: FontWeight.w700,
      ),
    ];

    final Widget content = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: 52, child: Center(child: HonooAppTitle())),
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
      key: const Key('public_landing_screen_root'),
      backgroundColor: isPhone ? HonooColor.background : Colors.transparent,
      body: Row(
        children: [
          Expanded(child: Container()),
          Align(
            alignment: Alignment.center,
            child: Container(
              color: HonooColor.background.withValues(alpha: 0.7),
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: content,
            ),
          ),
          Expanded(child: Container()),
        ],
      ),
    );

    if (!isPhone) {
      return Background(child: pageBody);
    }

    return pageBody;
  }
}
