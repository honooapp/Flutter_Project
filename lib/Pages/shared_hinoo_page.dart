import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Entities/hinoo.dart';
import 'package:honoo/Services/supabase_provider.dart';
import 'package:honoo/UI/hinoo_viewer.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Utility/responsive_layout.dart';
import 'package:honoo/Widgets/honoo_app_title.dart';
import 'package:honoo/Widgets/loading_spinner.dart';
import 'package:honoo/Widgets/responsive_footer_bar.dart';
import 'package:honoo/Widgets/desktop_carousel_arrows.dart';

import 'home_page.dart';
import 'placeholder_page.dart';

class SharedHinooPage extends StatefulWidget {
  const SharedHinooPage({super.key, required this.ownerId});

  final String ownerId;

  @override
  State<SharedHinooPage> createState() => _SharedHinooPageState();
}

class _SharedHinooPageState extends State<SharedHinooPage> {
  List<HinooDraft> _items = const [];
  bool _isLoading = true;
  int _currentIndex = 0;
  final cs.CarouselController _carouselController = cs.CarouselController();

  @override
  void initState() {
    super.initState();
    _loadHinoo();
  }

  Future<void> _loadHinoo() async {
    setState(() => _isLoading = true);
    try {
      final rows = await SupabaseProvider.client
          .from('hinoo')
          .select('pages,type,recipient_tag,created_at')
          .eq('user_id', widget.ownerId)
          .eq('type', 'personal')
          .order('created_at', ascending: false);

      final list = <HinooDraft>[];
      for (final row in (rows as List)) {
        final pages = row['pages'];
        if (pages is! List) continue;
        list.add(
          HinooDraft(
            pages: pages
                .whereType<Map<String, dynamic>>()
                .map((entry) => HinooSlide.fromJson(entry))
                .toList(),
            type: HinooType.personal,
            recipientTag: row['recipient_tag'] as String?,
          ),
        );
      }

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
          final double targetMaxW = viewW;
          final double footerReserved =
              footerIconSize + footerTopSpacing + footerBottomSpacing;
          final double availableH =
              (viewH - headerH - footerReserved).clamp(0.0, double.infinity);

          final Widget content = _isLoading
              ? const Center(child: LoadingSpinner())
              : (_items.isEmpty
                  ? Center(
                      child: Text(
                        'Nessun hinoo condiviso',
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
                          scrollPhysics: const PageScrollPhysics(),
                          onPageChanged: (index, reason) {
                            setState(() => _currentIndex = index);
                          },
                        ),
                      items: _items
                          .map(
                            (item) => SizedBox(
                              width: targetMaxW,
                              height: availableH,
                              child: HinooViewer(
                                draft: item,
                                maxHeight: availableH,
                                maxWidth: targetMaxW,
                              ),
                            ),
                          )
                          .toList(),
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
