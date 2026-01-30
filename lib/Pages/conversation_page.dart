
import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Controller/honoo_controller.dart';
import 'package:honoo/UI/honoo_card.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Widgets/loading_spinner.dart';
import 'package:honoo/Widgets/honoo_dialogs.dart';
import 'package:honoo/Widgets/honoo_app_title.dart';
import 'package:honoo/Widgets/responsive_footer_bar.dart';
import 'package:honoo/Utility/responsive_layout.dart';

import '../Entities/honoo.dart';
import 'reply_honoo_page.dart';
import 'home_page.dart';
import 'placeholder_page.dart';

class ConversationPage extends StatefulWidget {
  const ConversationPage({
    super.key,
    required this.honoo,
    this.readOnly = false,
  });

  final Honoo honoo;
  final bool readOnly;

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final cs.CarouselController _carouselController = cs.CarouselController();

  bool _isLoading = true;
  List<Honoo> _thread = []; // padre + reply in ordine cronologico
  int _currentIndex = 0;
  bool _savingToChest = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final list = await HonooController().getHonooHistory(widget.honoo);
      if (!mounted) return;
      setState(() {
        _thread = list;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('getHonooHistory error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      showHonooToast(
        context,
        message: 'Errore nel caricamento conversazione: $e',
      );
    }
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
          final ResponsiveLayoutMode layoutMode =
              ResponsiveLayout.modeForWidth(viewW);
          final double footerIconSize =
              ResponsiveLayout.footerIconSizeForMode(layoutMode);
          final double footerGap = ResponsiveLayout.footerGapForMode(layoutMode);
          final double footerBottomPadding =
              ResponsiveLayout.footerBottomPaddingForMode(layoutMode);
          final double footerSpacing = footerBottomPadding + safeBottom;
          final double footerTopSpacing = footerSpacing / 2;
          final double footerBottomSpacing =
              footerSpacing - footerTopSpacing;
          const double headerH = 52;
          final double targetMaxW = ResponsiveLayout.contentMaxWidth(viewW);
          final double footerReserved =
              footerIconSize + footerTopSpacing + footerBottomSpacing;
          final double availableH =
              (viewH - headerH - footerReserved).clamp(0.0, double.infinity);
          final HonooBuilderMetrics honooMetrics =
              ResponsiveLayout.honooBuilderMetrics(
            availableHeight: availableH,
            maxWidth: targetMaxW,
            mode: layoutMode,
          );
          final double horizontalPadding = layoutMode == ResponsiveLayoutMode.mobile ||
                  layoutMode == ResponsiveLayoutMode.tablet
              ? 0
              : 16;

          final Widget carousel = _isLoading
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
                      carouselController: _carouselController,
                      options: cs.CarouselOptions(
                        scrollDirection: Axis.vertical,
                        height: honooMetrics.height,
                        viewportFraction: 1.0,
                        enlargeCenterPage: false,
                        enableInfiniteScroll: false,
                        onPageChanged: (index, reason) {
                          setState(() => _currentIndex = index);
                        },
                      ),
                      items: _thread
                          .map(
                            (h) => SizedBox(
                              width: honooMetrics.width,
                              height: honooMetrics.height,
                              child: HonooCard(honoo: h),
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
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: targetMaxW),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding),
                      child: SizedBox(
                        width: honooMetrics.width,
                        height: honooMetrics.height,
                        child: carousel,
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
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const HomePage()),
                        (route) => false,
                      );
                    },
                  ),
                  if (!widget.readOnly)
                    ResponsiveFooterAction(
                      asset: "assets/icons/broken_heart.svg",
                      semanticsLabel: 'Broken heart',
                      size: footerIconSize,
                      splashRadius: 25,
                      tooltip: 'Cuore spezzato',
                      onPressed: (_thread.isEmpty || _savingToChest)
                          ? null
                          : () async {
                              setState(() => _savingToChest = true);
                              try {
                                final honoo = _thread[_currentIndex];
                                final saved =
                                    await HonooController().saveToChest(honoo);
                                if (!context.mounted) return;
                                showHonooToast(
                                  context,
                                  message: saved
                                      ? 'honoo salvato nel tuo Scrigno.'
                                      : 'Era già nel tuo Scrigno.',
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                showHonooToast(
                                  context,
                                  message: 'Errore durante il salvataggio: $e',
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _savingToChest = false);
                                }
                              }
                            },
                    ),
                  if (!widget.readOnly)
                    ResponsiveFooterAction(
                      asset: "assets/icons/reply.svg",
                      semanticsLabel: 'Reply',
                      colorFilter: const ColorFilter.mode(
                        HonooColor.onBackground,
                        BlendMode.srcIn,
                      ),
                      size: footerIconSize,
                      splashRadius: 25,
                      tooltip: 'Rispondi',
                      onPressed: (_thread.isEmpty || _savingToChest)
                          ? null
                          : () {
                              final honoo = _thread[_currentIndex];
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReplyHonooPage(
                                    originalHonoo: honoo,
                                    initialHintText: 'Scrivi la tua risposta...',
                                    initialImageHint:
                                        'Aggiungi un’immagine (opzionale)',
                                  ),
                                ),
                              );
                            },
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
