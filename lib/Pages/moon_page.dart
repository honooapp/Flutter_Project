import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Services/supabase_provider.dart';

import '../Entities/hinoo.dart';
import '../Entities/honoo.dart';
import 'home_page.dart';
import '../UI/hinoo_viewer.dart';
import '../UI/hinoo_typography.dart';
import '../UI/honoo_thread_view.dart';
import '../Utility/honoo_colors.dart';
import '../Utility/responsive_layout.dart';
import '../Widgets/loading_spinner.dart';
import '../Widgets/honoo_dialogs.dart';
import '../Widgets/honoo_app_title.dart';
import '../Widgets/responsive_footer_bar.dart';
import 'placeholder_page.dart';
import 'reply_honoo_page.dart';
import 'new_hinoo_page.dart';
import '../Controller/honoo_controller.dart';
import '../Controller/hinoo_controller.dart';

class MoonPage extends StatefulWidget {
  const MoonPage({super.key});

  @override
  State<MoonPage> createState() => _MoonPageState();
}

class _MoonPageState extends State<MoonPage> {
  bool _isLoading = true;
  List<_MoonItem> _items = [];
  int _currentIndex = 0;
  final cs.CarouselController _carouselController = cs.CarouselController();
  DateTime? _lastScroll;

  @override
  void initState() {
    super.initState();
    _loadMoonContent();
  }

  Future<void> _loadMoonContent() async {
    try {
      final rows = await SupabaseProvider.client
          .from('moon_public')
          .select('id,user_id,kind,pages,text,image_url,recipient_tag,created_at')
          .order('created_at', ascending: false);

      final List<_MoonItem> items = [];

      for (final row in (rows as List)) {
        if (row is! Map) continue;
        final String kind = row['kind']?.toString() ?? '';
        final created =
            DateTime.tryParse((row['created_at'] ?? '').toString()) ??
                DateTime.fromMillisecondsSinceEpoch(0);
        if (kind == 'honoo') {
          final honoo = Honoo.fromMap(row.cast<String, dynamic>());
          final String? ownerId = row['user_id']?.toString();
          if ((honoo.recipientTag ?? '').isEmpty && ownerId != null) {
            honoo.recipientTag = ownerId;
          }
          items.add(_MoonItem.honoo(honoo, created));
        } else if (kind == 'hinoo') {
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
            final String? hinooId = row['id']?.toString();
            final String? ownerId = row['user_id']?.toString();
            items.add(_MoonItem.hinoo(draft, created,
                hinooId: hinooId, ownerId: ownerId));
          }
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double availHeight = constraints.maxHeight;
            final ResponsiveLayoutMode layoutMode =
                ResponsiveLayout.modeForWidth(constraints.maxWidth);
            final double footerIconSize =
                ResponsiveLayout.footerIconSizeForMode(layoutMode);
            final double footerGap =
                ResponsiveLayout.footerGapForMode(layoutMode);
            final double footerBottomPadding =
                ResponsiveLayout.footerBottomPaddingForMode(layoutMode);
            final double footerSpacing = footerBottomPadding;
            final double footerTopSpacing = footerSpacing / 2;
            final double footerBottomSpacing =
                footerSpacing - footerTopSpacing;
            final double footerReserved =
                footerIconSize + footerTopSpacing + footerBottomSpacing;
            final double centerHeight =
                (availHeight - headerHeight - footerReserved)
                    .clamp(0.0, double.infinity);
            final double targetMaxWidth = layoutMode == ResponsiveLayoutMode.mobile
                ? constraints.maxWidth
                : ResponsiveLayout.contentMaxWidth(constraints.maxWidth);
            final bool isCompact = layoutMode == ResponsiveLayoutMode.mobile ||
                layoutMode == ResponsiveLayoutMode.tablet;
            final HonooBuilderMetrics honooMetrics =
                ResponsiveLayout.honooBuilderMetrics(
              availableHeight: centerHeight,
              maxWidth: targetMaxWidth,
              mode: layoutMode,
            );
            final _MoonItem? current =
                _items.isEmpty ? null : _items[_currentIndex];
            final double displayHeight = current?.honoo != null
                ? honooMetrics.height
                : centerHeight;
            final double horizontalPadding = isCompact ? 0 : 16;

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
                        height: displayHeight,
                        child: _buildBody(
                          displayHeight,
                          centerHeight,
                          targetMaxWidth,
                          honooMetrics,
                          isCompact,
                          horizontalPadding,
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
                      asset: 'assets/icons/home_onTertiary.svg',
                      semanticsLabel: 'Home',
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
                    ResponsiveFooterAction(
                      asset: 'assets/icons/heart.svg',
                      semanticsLabel: 'Heart',
                      size: footerIconSize,
                      splashRadius: 25,
                      tooltip: 'Salva nel tuo Cuore',
                      onPressed: _saveCurrentToChest,
                    ),
                    ResponsiveFooterAction(
                      asset: 'assets/icons/reply.svg',
                      semanticsLabel: 'Reply',
                      size: footerIconSize,
                      splashRadius: 25,
                      tooltip: 'Rispondi',
                      onPressed: () => _showReplyChoice(),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(
    double bodyHeight,
    double availableHeight,
    double maxWidth,
    HonooBuilderMetrics honooMetrics,
    bool isCompact,
    double horizontalPadding,
  ) {
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
      child = FocusableActionDetector(
        autofocus: true,
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.arrowLeft):
              const _ArrowIntent(-1),
          LogicalKeySet(LogicalKeyboardKey.arrowRight):
              const _ArrowIntent(1),
        },
        actions: {
          _ArrowIntent: CallbackAction<_ArrowIntent>(
            onInvoke: (intent) {
              _animateToIndex(_currentIndex + intent.delta);
              return null;
            },
          ),
        },
        child: SizedBox(
          key: ValueKey('moon_content_${_items.length}'),
          height: bodyHeight,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Listener(
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) {
                  _handlePointerScroll(event);
                }
              },
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.stylus,
                    PointerDeviceKind.trackpad,
                  },
                ),
                child: cs.CarouselSlider.builder(
                  carouselController: _carouselController,
                  itemCount: _items.length,
                  options: cs.CarouselOptions(
                    height: bodyHeight,
                    viewportFraction: 1.0,
                    enableInfiniteScroll: false,
                    padEnds: true,
                    enlargeCenterPage: false,
                    scrollPhysics: const BouncingScrollPhysics(),
                    onPageChanged: (index, _) {
                      setState(() => _currentIndex = index);
                    },
                  ),
                  itemBuilder: (context, index, realIndex) {
                    final item = _items[index];
                    return Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: _buildMoonItem(
                        item,
                        availableHeight,
                        maxWidth,
                        honooMetrics,
                      ),
                    );
                  },
                ),
              ),
            ),
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

  Widget _buildMoonItem(
    _MoonItem item,
    double maxHeight,
    double maxWidth,
    HonooBuilderMetrics honooMetrics,
  ) {
    final String identity;
    final Widget content;

    if (item.honoo != null) {
      final honoo = item.honoo!;
      final String? dbId = honoo.dbId;
      final int localId = honoo.id;
      final String fallback =
          localId != 0 ? localId.toString() : item.createdAt.toIso8601String();
      identity = 'moon_honoo_${dbId ?? fallback}';
      content = SizedBox(
        width: honooMetrics.width,
        height: honooMetrics.height,
        child: HonooThreadView(root: honoo),
      );
    } else {
      final draft = item.hinoo!;
      identity =
          'moon_hinoo_${draft.hashCode}_${item.createdAt.toIso8601String()}';
    final Size hinooSize = ResponsiveLayout.fitAspectRatio(
      maxWidth,
      maxHeight,
      HinooTypography.aspectRatio,
    );
      final double cardW = hinooSize.width;
      final double cardH = hinooSize.height;
      final Widget viewer = HinooViewer(
        draft: draft,
        maxHeight: cardH,
        maxWidth: cardW,
        gapColor: Colors.white,
      );
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: cardH,
            maxWidth: cardW,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: cardW,
              height: cardH,
              child: viewer,
            ),
          ),
        ),
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

  void _handlePointerScroll(PointerScrollEvent event) {
    if (_items.isEmpty) return;
    final now = DateTime.now();
    if (_lastScroll != null &&
        now.difference(_lastScroll!) < const Duration(milliseconds: 200)) {
      return;
    }
    _lastScroll = now;
    final delta = event.scrollDelta.dy;
    if (delta > 0) {
      _animateToIndex(_currentIndex + 1);
    } else if (delta < 0) {
      _animateToIndex(_currentIndex - 1);
    }
  }

  void _animateToIndex(int target) {
    if (_items.isEmpty) return;
    final int clamped = target.clamp(0, _items.length - 1);
    if (clamped == _currentIndex) return;
    _carouselController.animateToPage(
      clamped,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _saveCurrentToChest() async {
    if (_items.isEmpty) return;
    final _MoonItem current = _items[_currentIndex];
    try {
      if (current.honoo != null) {
        final honoo = current.honoo!.copyWith(isFromMoonSaved: true);
        final saved = await HonooController().saveToChest(honoo);
        if (!mounted) return;
        showHonooToast(
          context,
          message: saved
              ? 'honoo salvato nello Scrigno.'
              : 'Era già nel tuo Scrigno.',
        );
        return;
      }
      if (current.hinoo != null) {
        final draft = current.hinoo!.copyWith(
          type: HinooType.personal,
          isFromMoonSaved: true,
        );
        await HinooController().saveToChest(draft);
        if (!mounted) return;
        showHonooToast(context, message: 'hinoo salvato nello Scrigno.');
      }
    } catch (e) {
      if (!mounted) return;
      showHonooToast(context, message: 'Errore: $e');
    }
  }

  Future<void> _showReplyChoice() async {
    if (_items.isEmpty) return;
    final _MoonItem current = _items[_currentIndex];
    final _ReplyChoice? choice = await showDialog<_ReplyChoice>(
      context: context,
      barrierDismissible: true,
      builder: (_) => HonooDialogShell(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Vuoi rispondere con\n un honoo o un hinoo?',
                style: HonooDialogStyles.title(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_ReplyChoice.honoo),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'honoo',
                    style: HonooDialogStyles.primaryAction(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_ReplyChoice.hinoo),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'hinoo',
                    style: HonooDialogStyles.primaryAction(),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(foregroundColor: Colors.white54),
                child: Text(
                  'Annulla',
                  style: HonooDialogStyles.tertiaryAction(),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (choice == null || !mounted) return;
    if (choice == _ReplyChoice.honoo && current.honoo != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReplyHonooPage(
            originalHonoo: current.honoo!,
            initialHintText: 'Scrivi la tua risposta...',
            initialImageHint: 'Aggiungi un’immagine (opzionale)',
          ),
        ),
      );
    } else if (choice == _ReplyChoice.hinoo && current.hinoo != null) {
      final String? replyTo = current.hinooId;
      if (replyTo == null || replyTo.isEmpty) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NewHinooPage(
            forcedType: HinooType.answer,
            recipientTag: current.ownerId,
            replyTo: replyTo,
          ),
        ),
      );
    }
  }
}

class _ArrowIntent extends Intent {
  const _ArrowIntent(this.delta);

  final int delta;
}

class _MoonItem {
  final Honoo? honoo;
  final HinooDraft? hinoo;
  final DateTime createdAt;
  final String? hinooId;
  final String? ownerId;

  const _MoonItem._(
    this.honoo,
    this.hinoo,
    this.createdAt, {
    this.hinooId,
    this.ownerId,
  });

  factory _MoonItem.honoo(Honoo h, DateTime createdAt) =>
      _MoonItem._(h, null, createdAt);

  factory _MoonItem.hinoo(
    HinooDraft h,
    DateTime createdAt, {
    String? hinooId,
    String? ownerId,
  }) =>
      _MoonItem._(
        null,
        h,
        createdAt,
        hinooId: hinooId,
        ownerId: ownerId,
      );
}

enum _ReplyChoice { honoo, hinoo }
