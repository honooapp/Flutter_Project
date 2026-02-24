import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Entities/honoo.dart';
import 'package:honoo/Services/honoo_service.dart';
import 'package:honoo/UI/honoo_card.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Utility/responsive_layout.dart';
import 'package:honoo/Widgets/honoo_app_title.dart';
import 'package:honoo/UI/thread_layout_scaffold.dart';
import 'package:honoo/Widgets/loading_spinner.dart';
import 'package:honoo/Widgets/responsive_footer_bar.dart';
import 'package:honoo/Widgets/desktop_carousel_arrows.dart';

import 'home_page.dart';
import 'placeholder_page.dart';

class SharedHonooPage extends StatefulWidget {
  const SharedHonooPage({super.key, required this.ownerId});

  final String ownerId;

  @override
  State<SharedHonooPage> createState() => _SharedHonooPageState();
}

class _SharedHonooPageState extends State<SharedHonooPage> {
  List<Honoo> _items = const [];
  bool _isLoading = true;
  int _currentIndex = 0;
  final cs.CarouselController _carouselController = cs.CarouselController();

  @override
  void initState() {
    super.initState();
    _loadHonoo();
  }

  Future<void> _loadHonoo() async {
    setState(() => _isLoading = true);
    try {
      final list =
          await HonooService.fetchUserHonoo(widget.ownerId, 'chest');
      if (!mounted) return;
      setState(() {
        _items = list;
        _currentIndex = _items.isEmpty ? 0 : _currentIndex.clamp(0, _items.length - 1);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ThreadLayoutScaffold(
      backgroundColor: HonooColor.background,
      header: HonooAppTitle(
        onTap: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const PlaceholderPage()),
            (route) => false,
          );
        },
      ),
      bodyBuilder: (context, viewW, availableH, layoutMode) {
        final metrics = ResponsiveLayout.honooBuilderMetrics(
          availableHeight: availableH,
          maxWidth: viewW,
          mode: layoutMode,
        );
        final Widget content = _isLoading
            ? const Center(child: LoadingSpinner())
            : (_items.isEmpty
                ? Center(
                    child: Text(
                      'Nessun honoo condiviso',
                      style: GoogleFonts.libreFranklin(
                        color: HonooColor.onBackground,
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  )
                : cs.CarouselSlider(
                    carouselController: _carouselController,
                    options: cs.CarouselOptions(
                      scrollDirection: Axis.horizontal,
                      height: availableH,
                      viewportFraction: 1.0,
                      enlargeCenterPage: false,
                      enableInfiniteScroll: false,
                      disableCenter: true,
                      scrollPhysics: (layoutMode == ResponsiveLayoutMode.mobile ||
                              layoutMode == ResponsiveLayoutMode.tablet)
                          ? const BouncingScrollPhysics()
                          : const PageScrollPhysics(),
                      onPageChanged: (index, reason) {
                        setState(() => _currentIndex = index);
                      },
                    ),
                    items: _items.map((item) {
                      return SizedBox(
                        width: metrics.width,
                        height: metrics.height,
                        child: HonooCard(honoo: item),
                      );
                    }).toList(),
                  ));

        final bool isDesktop = layoutMode == ResponsiveLayoutMode.desktop ||
            layoutMode == ResponsiveLayoutMode.wideDesktop ||
            layoutMode == ResponsiveLayoutMode.largeDesktop;
        if (!isDesktop || _items.length <= 1 || _isLoading) {
          return content;
        }
        return DesktopCarouselArrows(
          canPrev: _currentIndex > 0,
          canNext: _currentIndex < _items.length - 1,
          onPrev: () => _carouselController.animateToPage(
            (_currentIndex - 1).clamp(0, _items.length - 1),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          ),
          onNext: () => _carouselController.animateToPage(
            (_currentIndex + 1).clamp(0, _items.length - 1),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          ),
          arrowColor: Colors.white,
          child: content,
        );
      },
      footerBuilder: (context, mode, footerIconSize, footerGap,
          footerTopSpacing, footerBottomSpacing) {
        return ResponsiveFooterBar(
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
              onPressed: _goHome,
            ),
          ],
        );
      },
    );
  }
}

// no inline cover; show HonooCard with normal metrics
