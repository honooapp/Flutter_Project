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
import 'package:honoo/Services/supabase_provider.dart';

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
          final double targetMaxW = ResponsiveLayout.contentMaxWidth(viewW);
          final double footerReserved =
              footerIconSize + footerTopSpacing + footerBottomSpacing;
          final double availableH =
              (viewH - headerH - footerReserved).clamp(0.0, double.infinity);
          final metrics = ResponsiveLayout.honooBuilderMetrics(
            availableHeight: availableH,
            maxWidth: targetMaxW,
            mode: layoutMode,
          );
          final double horizontalPadding =
              layoutMode == ResponsiveLayoutMode.mobile ||
                      layoutMode == ResponsiveLayoutMode.tablet
                  ? 0
                  : 16;

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
                        height: metrics.height,
                        viewportFraction: 1.0,
                        enlargeCenterPage: false,
                        enableInfiniteScroll: false,
                        scrollPhysics: const PageScrollPhysics(),
                        onPageChanged: (index, reason) {
                          setState(() => _currentIndex = index);
                        },
                      ),
                      items: _items.map((item) {
                        final bool isReply =
                            (item.replyTo != null && item.replyTo!.isNotEmpty);
                        final String? uid =
                            SupabaseProvider.client.auth.currentUser?.id;
                        final bool isOwn = uid != null && item.userId == uid;
                        final Widget card = HonooCard(honoo: item);
                        if (isReply && !isOwn) {
                          return SizedBox(
                            width: metrics.width,
                            height: metrics.height,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: HonooColor.secondary, width: 2),
                              ),
                              child: card,
                            ),
                          );
                        }
                        return SizedBox(
                          width: metrics.width,
                          height: metrics.height,
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
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: targetMaxW),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: SizedBox(
                        width: metrics.width,
                        height: metrics.height,
                        child: () {
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
                        }(),
                      ),
                    ),
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
