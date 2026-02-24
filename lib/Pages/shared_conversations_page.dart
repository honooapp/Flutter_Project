import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Entities/honoo.dart';
import 'package:honoo/Services/honoo_service.dart';
// import removed: no direct use of HonooCard in this page
import 'package:honoo/UI/honoo_thread_view.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Utility/responsive_layout.dart';
import 'package:honoo/Widgets/honoo_app_title.dart';
import 'package:honoo/Widgets/loading_spinner.dart';
import 'package:honoo/Widgets/responsive_footer_bar.dart';
import 'package:honoo/Widgets/desktop_carousel_arrows.dart';
import 'package:honoo/UI/thread_layout_scaffold.dart';

// import removed: no direct use of HonooController here

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
  bool _isLoadingRoots = true;
  int _currentRootIndex = 0;
  final cs.CarouselController _rootCarousel = cs.CarouselController();

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
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingRoots = false);
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
                            width: viewW,
                            height: availableH,
                            child: HonooThreadView(root: root),
                          ),
                        )
                        .toList(),
                  ));

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
