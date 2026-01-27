import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Utility/responsive_layout.dart';
import 'package:honoo/Utility/utility.dart';
import 'package:honoo/Widgets/responsive_footer_bar.dart';
import 'package:honoo/UI/hinoo_typography.dart';

import '../../Pages/home_page.dart';

class CampanelliPage extends StatefulWidget {
  const CampanelliPage({super.key});

  @override
  State<CampanelliPage> createState() => _CampanelliPageState();
}

class _CampanelliPageState extends State<CampanelliPage> {
  int _campanelloIndex = 0;
  final PageController _pageController = PageController();

  static const String campanelloSirenaId = 'campanello_sirena';
  static const String campanelloPalombaroId = 'campanello_palombaro';
  static const String casaSirenaId = 'casa_sirena';
  static const String casaPalombaroId = 'casa_palombaro';
  static const String campanelloSirenaBg = 'assets/campanello1.png';
  static const String campanelloPalombaroBg = 'assets/campanello2.png';
  static const String casaSirenaBg =
      'assets/images/casa_sirena_con_scrigno.png';
  static const String casaPalombaroBg =
      'assets/images/casa_palombaro_con_scrigno.png';
  static const String scrignoOverlay = 'assets/icons/scrigno_di_carta.png';

  List<CampanelloData> _buildCampanelli() {
    return [
      CampanelloData(
        id: campanelloSirenaId,
        backgroundAsset: campanelloSirenaBg,
        text: Utility().campanelloExample1Text,
        linkedHouseId: casaSirenaId,
      ),
      CampanelloData(
        id: campanelloPalombaroId,
        backgroundAsset: campanelloPalombaroBg,
        text: Utility().campanelloExample2Text,
        linkedHouseId: casaPalombaroId,
      ),
    ];
  }

  Map<String, CasaData> _buildCase() {
    return {
      casaSirenaId: const CasaData(
        id: casaSirenaId,
        backgroundAsset: casaSirenaBg,
      ),
      casaPalombaroId: const CasaData(
        id: casaPalombaroId,
        backgroundAsset: casaPalombaroBg,
      ),
    };
  }

  List<_CampanelloPageData> _buildCampanelloPages(
    List<CampanelloData> campanelli,
  ) {
    return [
      _CampanelloPageData.intro(Utility().campanelliText),
      for (final campanello in campanelli)
        _CampanelloPageData.campanello(campanello),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HonooColor.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double maxWidth = constraints.maxWidth;
          final double maxHeight = constraints.maxHeight;
          final ResponsiveLayoutMode layoutMode =
              ResponsiveLayout.modeForWidth(maxWidth);
          final double targetMaxWidth = layoutMode == ResponsiveLayoutMode.mobile
              ? maxWidth
              : ResponsiveLayout.contentMaxWidth(maxWidth);

          final double footerIconSize =
              ResponsiveLayout.footerIconSizeForMode(layoutMode);
          final double footerGap = ResponsiveLayout.footerGapForMode(layoutMode);
          final double footerBottomPadding =
              ResponsiveLayout.footerBottomPaddingForMode(layoutMode);
          final double safeBottom = MediaQuery.of(context).viewPadding.bottom;
          final double footerSpacing = footerBottomPadding + safeBottom;
          final double footerTopSpacing = footerSpacing / 2;
          final double footerBottomSpacing =
              footerSpacing - footerTopSpacing;

          final double footerReserved =
              footerIconSize + footerTopSpacing + footerBottomSpacing;
          final double availableHeight =
              (maxHeight - footerReserved)
                  .clamp(0.0, double.infinity);
          final Size canvasSize = ResponsiveLayout.fitAspectRatio(
            targetMaxWidth,
            availableHeight,
            HinooTypography.aspectRatio,
          );
          final List<CampanelloData> campanelli = _buildCampanelli();
          final Map<String, CasaData> caseMap = _buildCase();
          final List<_CampanelloPageData> campanelloPages =
              _buildCampanelloPages(campanelli);

          final bool showCampanello = _campanelloIndex > 0;
          final bool showFooter = _pageController.hasClients
              ? (_pageController.page?.round() ?? 0) == 0
              : true;
          final ScrollPhysics pagePhysics = const PageScrollPhysics()
              .applyTo(const BouncingScrollPhysics());

          return Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                height: availableHeight,
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  physics: pagePhysics,
                  itemCount: 1 + campanelli.length,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 90),
                          curve: Curves.easeOutCubic,
                          constraints: BoxConstraints(maxWidth: targetMaxWidth),
                          child: SizedBox(
                            width: canvasSize.width,
                            height: canvasSize.height,
                            child: PageView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: pagePhysics,
                              itemCount: campanelloPages.length,
                              onPageChanged: (index) {
                                setState(() => _campanelloIndex = index);
                              },
                              itemBuilder: (context, pageIndex) {
                                return _CampanelloCard(
                                  data: campanelloPages[pageIndex],
                                  width: canvasSize.width,
                                  height: canvasSize.height,
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    }

                    final campanello = campanelli[index - 1];
                    return _CasaSection(
                      casa: caseMap[campanello.linkedHouseId]!,
                      scrignoAsset: scrignoOverlay,
                      footerIconSize: footerIconSize,
                      footerBottomSpacing: footerBottomSpacing,
                      width: maxWidth,
                      height: availableHeight,
                    );
                  },
                  onPageChanged: (_) => setState(() {}),
                ),
              ),
              if (showFooter)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ResponsiveFooterBar(
                    useSafeArea: false,
                    bottomPadding: footerBottomSpacing,
                    desiredGap: footerGap,
                    minGap: 16,
                    height: footerIconSize,
                    actions: [
                      ResponsiveFooterAction(
                        asset: "assets/icons/home.svg",
                        semanticsLabel: 'Home',
                        colorFilter: const ColorFilter.mode(
                          HonooColor.onBackground,
                          BlendMode.srcIn,
                        ),
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
                      if (showCampanello)
                        ResponsiveFooterAction(
                          asset: "assets/icons/campanello_bianco.png",
                          semanticsLabel: 'Campanello',
                          size: footerIconSize,
                          splashRadius: 25,
                          tooltip: 'Campanello',
                          onPressed: () {},
                          icon: Image.asset(
                            "assets/icons/campanello_bianco.png",
                            width: footerIconSize,
                            height: footerIconSize,
                            fit: BoxFit.contain,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class CampanelloData {
  final String id;
  final String backgroundAsset;
  final String text;
  final String linkedHouseId;

  const CampanelloData({
    required this.id,
    required this.backgroundAsset,
    required this.text,
    required this.linkedHouseId,
  });
}

class CasaData {
  final String id;
  final String backgroundAsset;

  const CasaData({
    required this.id,
    required this.backgroundAsset,
  });
}

class _CampanelloPageData {
  final bool isIntro;
  final String text;
  final CampanelloData? campanello;

  const _CampanelloPageData._({
    required this.isIntro,
    required this.text,
    this.campanello,
  });

  factory _CampanelloPageData.intro(String text) {
    return _CampanelloPageData._(isIntro: true, text: text);
  }

  factory _CampanelloPageData.campanello(CampanelloData campanello) {
    return _CampanelloPageData._(
      isIntro: false,
      text: campanello.text,
      campanello: campanello,
    );
  }
}


class _CampanelloCard extends StatelessWidget {
  const _CampanelloCard({
    required this.data,
    required this.width,
    required this.height,
  });

  final _CampanelloPageData data;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final double verticalPadding = HinooTypography.verticalPadding(width);
    final TextStyle textStyle = GoogleFonts.lora(
      fontSize: 18,
      height: HinooTypography.lineHeight,
      color: HonooColor.onBackground,
      fontWeight: FontWeight.w400,
    );

    final Widget text = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: HinooTypography.horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Center(
        child: Text(
          data.text,
          style: textStyle,
          textAlign: TextAlign.center,
        ),
      ),
    );

    if (data.isIntro) {
      return Center(
        child: SizedBox(
          width: width,
          height: height,
          child: text,
        ),
      );
    }

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                data.campanello!.backgroundAsset,
                fit: BoxFit.cover,
              ),
              text,
            ],
          ),
        ),
      ),
    );
  }
}

class _CasaSection extends StatelessWidget {
  const _CasaSection({
    required this.casa,
    required this.scrignoAsset,
    required this.footerIconSize,
    required this.footerBottomSpacing,
    required this.width,
    required this.height,
  });

  final CasaData casa;
  final String scrignoAsset;
  final double footerIconSize;
  final double footerBottomSpacing;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            casa.backgroundAsset,
            fit: BoxFit.cover,
          ),
          Positioned(
            bottom: footerBottomSpacing,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                scrignoAsset,
                width: footerIconSize,
                height: footerIconSize,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
