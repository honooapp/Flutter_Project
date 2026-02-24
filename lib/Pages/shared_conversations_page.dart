import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Entities/honoo.dart';
import 'package:honoo/Services/honoo_service.dart';
import 'package:honoo/UI/honoo_card.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Utility/responsive_layout.dart';
import 'package:honoo/Widgets/honoo_app_title.dart';
import 'package:honoo/Widgets/loading_spinner.dart';
import 'package:honoo/Widgets/responsive_footer_bar.dart';
import 'package:honoo/Widgets/desktop_carousel_arrows.dart';

import 'package:honoo/Controller/honoo_controller.dart';

import 'home_page.dart';
import 'placeholder_page.dart';

class SharedConversationsPage extends StatefulWidget {
  const SharedConversationsPage({super.key, required this.ownerId});

  final String ownerId;

  @override
  State<SharedConversationsPage> createState() =>
      _SharedConversationsPageState();
}

class _SharedConversationsPageState extends State<SharedConversationsPage> {
  List<Honoo> _roots = const [];
  List<Honoo> _thread = const [];
  bool _isLoadingRoots = true;
  bool _isLoadingThread = false;
  int _currentRootIndex = 0;
  int _currentThreadIndex = 0;
  final cs.CarouselController _rootCarousel = cs.CarouselController();
  final cs.CarouselController _threadCarousel = cs.CarouselController();

  @override
  void initState() {
    super.initState();
    _loadHonoo();
  }

  Future<void> _loadHonoo() async {
    setState(() => _isLoadingRoots = true);
    try {
      final list =
          await HonooService.fetchUserHonoo(widget.ownerId, 'chest');
      if (!mounted) return;
      setState(() {
        _roots = list;
        _currentRootIndex =
            _roots.isEmpty ? 0 : _currentRootIndex.clamp(0, _roots.length - 1);
        _isLoadingRoots = false;
      });
      if (_roots.isNotEmpty) {
        await _loadThreadFor(_roots[_currentRootIndex]);
      } else {
        if (mounted) {
          setState(() => _thread = const []);
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingRoots = false);
    }
  }

  Future<void> _loadThreadFor(Honoo root) async {
    setState(() => _isLoadingThread = true);
    try {
      final list = await HonooController().getHonooHistory(root);
      if (!mounted) return;
      setState(() {
        _thread = list;
        _currentThreadIndex =
            _thread.isEmpty ? 0 : _currentThreadIndex.clamp(0, _thread.length - 1);
        _isLoadingThread = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingThread = false);
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
    return Scaffold(
      backgroundColor: HonooColor.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double viewW = constraints.maxWidth;
          final double viewH = constraints.maxHeight;
          final double safeBottom = MediaQuery.of(context).viewPadding.bottom;
          final layoutMode = ResponsiveLayout.modeForWidth(viewW);
          final double footerIconSize =
              ResponsiveLayout.footerIconSizeForMode(layoutMode);
          final double footerGap = ResponsiveLayout.footerGapForMode(layoutMode);
          final double footerBottomPadding =
              ResponsiveLayout.footerBottomPaddingForMode(layoutMode);
          final double footerSpacing = footerBottomPadding + safeBottom;
          final double footerTopSpacing = footerSpacing / 2;
          final double footerBottomSpacing = footerSpacing - footerTopSpacing;
          const double headerH = 52;
          final double targetMaxW = viewW;
          final double footerReserved =
              footerIconSize + footerTopSpacing + footerBottomSpacing;
          final double availableH =
              (viewH - headerH - footerReserved).clamp(0.0, double.infinity);
          const double horizontalPadding = 0;

          final Widget threads = _isLoadingRoots
              ? const Center(child: LoadingSpinner())
              : (_roots.isEmpty
                  ? Center(
                      child: Text(
                        'Nessuna conversazione condivisa',
                        style: GoogleFonts.libreFranklin(
                          color: HonooColor.onBackground,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    )
                  : cs.CarouselSlider(
                      carouselController: _rootCarousel,
                      options: cs.CarouselOptions(
                        scrollDirection: Axis.horizontal,
                        height: availableH,
                        viewportFraction: 1.0,
                        enlargeCenterPage: false,
                        enableInfiniteScroll: false,
                        disableCenter: true,
                        scrollPhysics: const PageScrollPhysics(),
                        onPageChanged: (index, reason) {
                          setState(() => _currentRootIndex = index);
                        },
                      ),
                      items: _roots
                          .map(
                            (root) => SizedBox(
                              width: targetMaxW,
                              height: availableH,
                              child: HonooThreadView(root: root),
                            ),
                          )
                          .toList(),
                    ));

          final Widget rootCarousel = _isLoadingRoots
              ? const Center(child: LoadingSpinner())
              : (_roots.isEmpty
                  ? Center(
                      child: Text(
                        'Nessuna conversazione condivisa',
                        style: GoogleFonts.libreFranklin(
                          color: HonooColor.onBackground,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    )
                  : cs.CarouselSlider(
                      carouselController: _rootCarousel,
                      options: cs.CarouselOptions(
                        scrollDirection: Axis.horizontal,
                        height: topHeight,
                        viewportFraction: 1.0,
                        enlargeCenterPage: false,
                        enableInfiniteScroll: false,
                        disableCenter: true,
                        scrollPhysics: const PageScrollPhysics(),
                        onPageChanged: (index, reason) async {
                          setState(() => _currentRootIndex = index);
                          await _loadThreadFor(_roots[index]);
                        },
                      ),
                      items: _roots
                          .map(
                            (item) => SizedBox(
                              width: targetMaxW,
                              height: topHeight,
                              child: HonooCard(honoo: item),
                            ),
                          )
                          .toList(),
                    ));

          final Widget threadCarousel = _isLoadingThread
              ? const Center(child: LoadingSpinner())
              : (_thread.isEmpty
                  ? Center(
                      child: Text(
                        'Nessuna conversazione',
                        style: GoogleFonts.libreFranklin(
                          color: HonooColor.onBackground,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    )
                  : cs.CarouselSlider(
                      carouselController: _threadCarousel,
                      options: cs.CarouselOptions(
                        scrollDirection: Axis.vertical,
                        height: bottomHeight,
                        viewportFraction: 1.0,
                        enlargeCenterPage: false,
                        enableInfiniteScroll: false,
                        onPageChanged: (index, reason) {
                          setState(() => _currentThreadIndex = index);
                        },
                      ),
                      items: _thread.map((item) {
                        final Widget card = HonooCard(honoo: item);
                        return SizedBox(
                          width: targetMaxW,
                          height: bottomHeight,
                          child: card,
                        );
                      }).toList(),
                    ));

          return Column(
            children: [
              SizedBox(
                height: headerH,
                child: Center(
                  child: HonooAppTitle(
                    onTap: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (_) => const PlaceholderPage()),
                        (route) => false,
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: targetMaxW,
                    height: availableH,
                    child: () {
                      final bool isDesktop = layoutMode == ResponsiveLayoutMode.desktop ||
                          layoutMode == ResponsiveLayoutMode.wideDesktop ||
                          layoutMode == ResponsiveLayoutMode.largeDesktop;
                      if (!isDesktop || _roots.length <= 1 || _isLoadingRoots) {
                        return threads;
                      }
                      return DesktopCarouselArrows(
                        canPrev: _currentRootIndex > 0,
                        canNext: _currentRootIndex < _roots.length - 1,
                        onPrev: () => _rootCarousel.animateToPage(
                          (_currentRootIndex - 1).clamp(0, _roots.length - 1),
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                        ),
                        onNext: () => _rootCarousel.animateToPage(
                          (_currentRootIndex + 1).clamp(0, _roots.length - 1),
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                        ),
                        arrowColor: Colors.white,
                        child: threads,
                      );
                    }(),
                  ),
                ),
              ),
              SizedBox(height: footerTopSpacing),
              ResponsiveFooterBar(
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
              ),
            ],
          );
        },
      ),
    );
  }
}
