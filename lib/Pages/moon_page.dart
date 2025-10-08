import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:honoo/Services/supabase_provider.dart';

import '../Entities/hinoo.dart';
import '../Entities/honoo.dart';
import 'chest_page.dart';
import 'coming_soon_page.dart';
import '../Services/honoo_service.dart';
import '../UI/hinoo_viewer.dart';
import '../UI/honoo_thread_view.dart';
import '../Utility/honoo_colors.dart';
import '../Utility/utility.dart';
import '../Utility/responsive_layout.dart';
import '../Widgets/loading_spinner.dart';
import '../Widgets/honoo_dialogs.dart';

class MoonPage extends StatefulWidget {
  const MoonPage({super.key});

  @override
  State<MoonPage> createState() => _MoonPageState();
}

class _MoonPageState extends State<MoonPage> {
  bool _isLoading = true;
  List<_MoonItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadMoonContent();
  }

  Future<void> _loadMoonContent() async {
    try {
      final honoo = await HonooService.fetchPublicHonoo();

      final rows = await SupabaseProvider.client
          .from('hinoo')
          .select('pages,recipient_tag,created_at')
          .eq('type', 'moon')
          .order('created_at', ascending: false);

      final List<_MoonItem> items = [];

      for (final h in honoo) {
        final created = DateTime.tryParse(h.createdAt) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        items.add(_MoonItem.honoo(h, created));
      }

      for (final row in (rows as List)) {
        final pages = row['pages'];
        if (pages is List) {
          final draft = HinooDraft(
            pages: pages
                .whereType<Map<String, dynamic>>()
                .map(HinooSlide.fromJson)
                .toList(),
            type: HinooType.moon,
            recipientTag: row['recipient_tag'] as String?,
          );
          final created =
              DateTime.tryParse((row['created_at'] ?? '').toString()) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
          items.add(_MoonItem.hinoo(draft, created));
        }
      }

      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Errore caricamento Moon: $e');
      if (mounted) {
        showHonooToast(
          context,
          message: 'Errore caricamento Moon: $e',
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double headerHeight = 52;
    const double footerHeight = 60;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double availHeight = constraints.maxHeight;
            final double centerHeight =
                (availHeight - headerHeight - footerHeight)
                    .clamp(0.0, double.infinity);
            final double targetMaxWidth =
                ResponsiveLayout.contentMaxWidth(constraints.maxWidth);

            return Column(
              children: [
                SizedBox(
                  height: headerHeight,
                  child: Center(
                    child: Text(
                      Utility().appName,
                      style: GoogleFonts.libreFranklin(
                        color: HonooColor.secondary,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 90),
                      curve: Curves.easeOutCubic,
                      constraints: BoxConstraints(
                        maxWidth: targetMaxWidth,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: centerHeight,
                        child: _buildBody(centerHeight, targetMaxWidth),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: footerHeight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: SvgPicture.asset(
                          'assets/icons/home_onTertiary.svg',
                          semanticsLabel: 'Home',
                        ),
                        iconSize: 60,
                        splashRadius: 25,
                        tooltip: 'Indietro',
                        onPressed: () => Navigator.pop(context),
                      ),
                      SizedBox(width: 5.w),
                      IconButton(
                        icon: SvgPicture.asset(
                          'assets/icons/heart.svg',
                          semanticsLabel: 'Heart',
                        ),
                        iconSize: 60,
                        splashRadius: 25,
                        tooltip: 'Salva nel tuo Cuore',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChestPage(),
                            ),
                          );
                        },
                      ),
                      SizedBox(width: 5.w),
                      IconButton(
                        icon: SvgPicture.asset(
                          'assets/icons/reply.svg',
                          semanticsLabel: 'Reply',
                        ),
                        iconSize: 60,
                        splashRadius: 25,
                        tooltip: 'Rispondi',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ComingSoonPage(
                                header: Utility().replyMoonHeader,
                                quote: Utility().shakespeare,
                                bibliography: Utility().bibliography,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(double maxHeight, double maxWidth) {
    Widget child;
    if (_isLoading) {
      child = const Center(
        key: ValueKey('moon_loading'),
        child: LoadingSpinner(color: HonooColor.background),
      );
    } else if (_items.isEmpty) {
      child = Center(
        key: const ValueKey('moon_empty'),
        child: Text(
          'Nessun contenuto sulla Luna',
          style: GoogleFonts.libreFranklin(
            color: HonooColor.onTertiary,
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      child = SizedBox(
        key: ValueKey('moon_content_${_items.length}'),
        height: maxHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: cs.CarouselSlider.builder(
            itemCount: _items.length,
            options: cs.CarouselOptions(
              height: maxHeight,
              viewportFraction: 1.0,
              enableInfiniteScroll: false,
              padEnds: true,
              enlargeCenterPage: false,
              scrollPhysics: const BouncingScrollPhysics(),
            ),
            itemBuilder: (context, index, realIndex) {
              final item = _items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildMoonItem(item, maxHeight, maxWidth),
              );
            },
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: child,
    );
  }

  Widget _buildMoonItem(_MoonItem item, double maxHeight, double maxWidth) {
    final String identity;
    final Widget content;

    if (item.honoo != null) {
      final honoo = item.honoo!;
      final String? dbId = honoo.dbId;
      final int localId = honoo.id;
      final String fallback =
          localId != 0 ? localId.toString() : item.createdAt.toIso8601String();
      identity = 'moon_honoo_${dbId ?? fallback}';
      content = HonooThreadView(root: honoo);
    } else {
      final draft = item.hinoo!;
      identity =
          'moon_hinoo_${draft.hashCode}_${item.createdAt.toIso8601String()}';
      content = HinooViewer(
        draft: draft,
        maxHeight: maxHeight,
        maxWidth: maxWidth,
        gapColor: Colors.white,
        showDotsBorder: true,
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(
        key: ValueKey(identity),
        child: content,
      ),
    );
  }
}

class _MoonItem {
  final Honoo? honoo;
  final HinooDraft? hinoo;
  final DateTime createdAt;

  const _MoonItem._(this.honoo, this.hinoo, this.createdAt);

  factory _MoonItem.honoo(Honoo h, DateTime createdAt) =>
      _MoonItem._(h, null, createdAt);

  factory _MoonItem.hinoo(HinooDraft h, DateTime createdAt) =>
      _MoonItem._(null, h, createdAt);
}
