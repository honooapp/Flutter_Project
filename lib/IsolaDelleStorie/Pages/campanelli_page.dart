import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;
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
  int _currentIndex = 0;

  static const String _example1Bg = 'assets/campanello1.png';
  static const String _example2Bg = 'assets/campanello2.png';

  List<_CampanelloCardData> _buildPages() {
    return [
      _CampanelloCardData.intro(Utility().campanelliText),
      _CampanelloCardData.example(
        backgroundAsset: _example1Bg,
        text: Utility().campanelloExample1Text,
      ),
      _CampanelloCardData.example(
        backgroundAsset: _example2Bg,
        text: Utility().campanelloExample2Text,
      ),
    ];
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
          final List<_CampanelloCardData> pages = _buildPages();

          final bool showCampanello = _currentIndex > 0;

          return Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 90),
                  curve: Curves.easeOutCubic,
                  constraints: BoxConstraints(maxWidth: targetMaxWidth),
                  child: SizedBox(
                    width: canvasSize.width,
                    height: canvasSize.height,
                    child: cs.CarouselSlider.builder(
                      itemCount: pages.length,
                      options: cs.CarouselOptions(
                        height: canvasSize.height,
                        viewportFraction: 1.0,
                        enableInfiniteScroll: false,
                        padEnds: true,
                        enlargeCenterPage: false,
                        scrollPhysics: const BouncingScrollPhysics(),
                        onPageChanged: (index, _) {
                          setState(() => _currentIndex = index);
                        },
                      ),
                      itemBuilder: (context, index, realIdx) {
                        return _CampanelloCard(
                          data: pages[index],
                          width: canvasSize.width,
                          height: canvasSize.height,
                        );
                      },
                    ),
                  ),
                ),
              ),
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
                          MaterialPageRoute(builder: (_) => const HomePage()),
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

class _CampanelloCardData {
  final String? backgroundAsset;
  final String text;
  final bool isIntro;

  const _CampanelloCardData._({
    required this.text,
    required this.isIntro,
    this.backgroundAsset,
  });

  factory _CampanelloCardData.intro(String text) {
    return _CampanelloCardData._(text: text, isIntro: true);
  }

  factory _CampanelloCardData.example({
    required String backgroundAsset,
    required String text,
  }) {
    return _CampanelloCardData._(
      text: text,
      isIntro: false,
      backgroundAsset: backgroundAsset,
    );
  }
}

class _CampanelloCard extends StatelessWidget {
  const _CampanelloCard({
    required this.data,
    required this.width,
    required this.height,
  });

  final _CampanelloCardData data;
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
                data.backgroundAsset!,
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
