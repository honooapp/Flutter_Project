import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../Entities/hinoo.dart';
import '../Entities/honoo.dart';
import 'chest_page.dart';
import 'coming_soon_page.dart';
import 'home_page.dart';
import '../Services/honoo_service.dart';
import '../Services/hinoo_service.dart';
import '../UI/hinoo_viewer.dart';
import '../UI/honoo_thread_view.dart';
import '../Utility/honoo_colors.dart';
import '../Utility/utility.dart';
import '../Utility/responsive_layout.dart';
import '../Widgets/loading_spinner.dart';
import '../Widgets/honoo_dialogs.dart';
import '../Widgets/honoo_app_title.dart';
import 'placeholder_page.dart';

class MoonPage extends StatefulWidget {
  const MoonPage({super.key});

  @override
  State<MoonPage> createState() => _MoonPageState();
}

class _MoonPageState extends State<MoonPage> {
  bool _isLoading = true;
  List<_MoonItem> _items = [];
  int _currentIndex = 0;
  bool _honooHasMore = true;
  bool _hinooHasMore = true;
  DateTime? _oldestHonoo;
  DateTime? _oldestHinoo;
  bool _isPrefetching = false;
  final Set<String> _honooIds = <String>{};
  final Set<String> _hinooIds = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMoonContent(refresh: true);
    });
  }

  Future<void> _loadMoonContent({bool refresh = false}) async {
    if (refresh) {
      _resetPagination();
    }

    if (refresh) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final results = await Future.wait([
        _fetchHonooPage(refresh: true),
        _fetchHinooPage(refresh: true),
      ]);

      if (!mounted) return;

      final combined = <_MoonItem>[...results[0], ...results[1]]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _items = combined;
        _isLoading = false;
      });

      unawaited(_maybePrefetch(_currentIndex));
    } catch (e) {
      debugPrint('Errore caricamento Moon: $e');
      if (mounted) {
        showHonooToast(
          context,
          message: 'Errore caricamento Moon: $e',
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetPagination() {
    _items = [];
    _honooIds.clear();
    _hinooIds.clear();
    _honooHasMore = true;
    _hinooHasMore = true;
    _oldestHonoo = null;
    _oldestHinoo = null;
    _currentIndex = 0;
  }

  Future<List<_MoonItem>> _fetchHonooPage({required bool refresh}) async {
    final list = await HonooService.fetchPublicHonoo(
      limit: HonooService.defaultPageSize,
      before: refresh ? null : _oldestHonoo,
    );

    if (list.length < HonooService.defaultPageSize) {
      _honooHasMore = false;
    }

    final items = <_MoonItem>[];
    for (final honoo in list) {
      final key = _honooKey(honoo);
      if (!_honooIds.add(key)) continue;
      final created = DateTime.tryParse(honoo.createdAt) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      if (_oldestHonoo == null || created.isBefore(_oldestHonoo!)) {
        _oldestHonoo = created;
      }
      items.add(_MoonItem.honoo(honoo, created));
    }
    return items;
  }

  Future<List<_MoonItem>> _fetchHinooPage({required bool refresh}) async {
    final rows = await HinooService.fetchHinooEntries(
      type: HinooType.moon,
      limit: HinooService.defaultPageSize,
      before: refresh ? null : _oldestHinoo,
    );

    if (rows.length < HinooService.defaultPageSize) {
      _hinooHasMore = false;
    }

    final items = <_MoonItem>[];
    for (final row in rows) {
      final dynamic rawId = row['id'];
      final String? id = rawId?.toString();
      if (id == null || id.isEmpty) continue;
      if (!_hinooIds.add(id)) continue;

      final pages = row['pages'];
      if (pages is! List) continue;

      final draft = HinooDraft(
        pages: pages
            .whereType<Map<String, dynamic>>()
            .map(HinooSlide.fromJson)
            .toList(),
        type: HinooType.moon,
        recipientTag: row['recipient_tag'] as String?,
      );

      final created = DateTime.tryParse((row['created_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);

      if (_oldestHinoo == null || created.isBefore(_oldestHinoo!)) {
        _oldestHinoo = created;
      }

      items.add(_MoonItem.hinoo(draft, created));
    }
    return items;
  }

  void _handlePageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    unawaited(_maybePrefetch(index));
  }

  Future<void> _maybePrefetch(int index) async {
    if (_isPrefetching) return;
    const threshold = 3;
    if (_items.length - index > threshold) return;
    if (!_honooHasMore && !_hinooHasMore) return;

    _isPrefetching = true;
    try {
      final futures = <Future<List<_MoonItem>>>[];
      if (_honooHasMore) {
        futures.add(_fetchHonooPage(refresh: false));
      }
      if (_hinooHasMore) {
        futures.add(_fetchHinooPage(refresh: false));
      }
      if (futures.isEmpty) return;
      final batches = await Future.wait(futures, eagerError: true);

      var appended = false;
      final merged = List<_MoonItem>.from(_items);
      for (final batch in batches) {
        if (batch.isEmpty) continue;
        merged.addAll(batch);
        appended = true;
      }

      if (appended) {
        merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      if (mounted && (appended || !_honooHasMore || !_hinooHasMore)) {
        setState(() {
          if (appended) {
            _items = merged;
          }
        });
      }
    } catch (e) {
      debugPrint('Moon prefetch error: $e');
    } finally {
      _isPrefetching = false;
    }
  }

  String _honooKey(Honoo honoo) {
    if (honoo.dbId != null && honoo.dbId!.isNotEmpty) {
      return honoo.dbId!;
    }
    return '${honoo.id}_${honoo.createdAt}_${honoo.text.hashCode}';
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
                        tooltip: 'Home',
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const HomePage()),
                            (route) => false,
                          );
                        },
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
              onPageChanged: (index, _) => _handlePageChanged(index),
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
