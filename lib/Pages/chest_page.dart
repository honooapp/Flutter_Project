import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;

import 'package:honoo/Services/supabase_provider.dart';
import 'package:honoo/UI/HinooBuilder/services/download_saver.dart';

import '../Controller/honoo_controller.dart';
import '../Controller/hinoo_controller.dart';
import '../Entities/honoo.dart';
import '../Entities/hinoo.dart';

import '../UI/honoo_thread_view.dart';
import '../UI/hinoo_viewer.dart';

import '../Utility/honoo_colors.dart';
import '../Utility/responsive_layout.dart';

import '../Widgets/honoo_dialogs.dart';
import '../Widgets/loading_spinner.dart';
import '../Widgets/honoo_app_title.dart';
import '../Widgets/luna_fissa.dart';
import '../Widgets/responsive_footer_bar.dart';

import 'reply_honoo_page.dart';
import 'home_page.dart';
import 'placeholder_page.dart';

class ChestPage extends StatefulWidget {
  const ChestPage({super.key});

  @override
  State<ChestPage> createState() => _ChestPageState();
}

class _ChestPageState extends State<ChestPage> {
  final HonooController ctrl = HonooController();
  final HinooController _hinooController = HinooController();

  int _currentIndex = 0;
  List<_ChestItem> _items = const [];
  List<_HinooRow> _hinoo = const [];
  bool _isHinooLoading = true;

  // Desktop
  static const double honooRightDesktop = 40;
  static const double hinooRightDesktop = 30;
  static const double topDesktop = 10;

  // Mobile
  static const double rightMobile = 8;
  static const double honooTopMobile = 45;
  static const double hinooTopMobile = 10;

  // Key stabili per cattura PNG
  final Map<String, GlobalKey> _captureKeys = <String, GlobalKey>{};
  GlobalKey _keyFor(String identity) =>
      _captureKeys.putIfAbsent(identity, () => GlobalKey());

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    ctrl.loadChest();
    _loadHinoo();
  }

  Future<void> _loadHinoo() async {
    final uid = SupabaseProvider.client.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) setState(() => _isHinooLoading = false);
      return;
    }

    if (mounted) setState(() => _isHinooLoading = true);

    try {
      final client = SupabaseProvider.client;
      final rows = await client
          .from('hinoo')
          .select('id,pages,type,recipient_tag,created_at')
          .eq('user_id', uid)
          .eq('type', 'personal')
          .order('created_at', ascending: false);

      final list = <_HinooRow>[];
      for (final r in (rows as List)) {
        final pages = r['pages'];
        if (pages is! List) continue;

        final draft = HinooDraft(
          pages: pages
              .whereType<Map<String, dynamic>>()
              .map((e) => HinooSlide.fromJson(e))
              .toList(),
          type: HinooType.personal,
          recipientTag: r['recipient_tag'] as String?,
        );

        final created = DateTime.tryParse((r['created_at'] ?? '').toString()) ??
            DateTime.now();

        final String? id = r['id']?.toString();
        if (id != null && id.isNotEmpty) {
          list.add(_HinooRow(id: id, draft: draft, createdAt: created));
        }
      }

      if (!mounted) return;
      setState(() {
        _hinoo = list;
        _isHinooLoading = false;
        _rebuildItems();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isHinooLoading = false);
    }
  }

  void _rebuildItems() {
    final honooItems = ctrl.personal.map<_ChestItem>((h) {
      final dt = DateTime.tryParse(h.createdAt) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return _ChestItem.honoo(h, dt);
    }).toList();

    final hinooItems =
        _hinoo.map<_ChestItem>((r) => _ChestItem.hinoo(r)).toList();

    _items = [...honooItems, ...hinooItems]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (_currentIndex >= _items.length) {
      _currentIndex = _items.isEmpty ? 0 : _items.length - 1;
    }
  }

  // --- helper menu
  bool _isPersonal(Honoo h) => h.type == HonooType.personal;
  bool _hasReplies(Honoo h) => h.hasReplies == true;
  bool _isFromMoonSaved(Honoo h) => h.isFromMoonSaved == true;

  Widget _footerForHonoo(
    Honoo? current, {
    required double iconSize,
    required double gap,
    required double bottomPadding,
  }) {

    if (current == null) {
      return ResponsiveFooterBar(
        useSafeArea: false,
        bottomPadding: bottomPadding,
        desiredGap: gap,
        minGap: 16,
        height: iconSize,
        actions: [
          ResponsiveFooterAction(
            asset: "assets/icons/home.svg",
            semanticsLabel: 'Home',
            size: iconSize,
            splashRadius: 25,
            tooltip: 'Home',
            onPressed: _goHome,
          ),
        ],
      );
    }

    final actions = <ResponsiveFooterAction>[
      ResponsiveFooterAction(
        asset: "assets/icons/home.svg",
        semanticsLabel: 'Home',
        colorFilter: const ColorFilter.mode(
          HonooColor.onBackground,
          BlendMode.srcIn,
        ),
        size: iconSize,
        splashRadius: 25,
        tooltip: 'Home',
        onPressed: _goHome,
      ),
    ];

    if (_isPersonal(current) &&
        !_hasReplies(current) &&
        !_isFromMoonSaved(current)) {
      actions.add(
        ResponsiveFooterAction(
          asset: "assets/icons/moon.svg",
          semanticsLabel: 'Luna',
          colorFilter: const ColorFilter.mode(
            HonooColor.onBackground,
            BlendMode.srcIn,
          ),
          size: iconSize,
          splashRadius: 25,
          tooltip: 'Spedisci sulla Luna',
          onPressed: () async {
            final ok = await HonooController().sendToMoon(current);
            if (!mounted) return;
            showHonooToast(
              context,
              message: ok ? 'Spedito sulla Luna' : 'Già presente sulla Luna',
            );
          },
        ),
      );
    } else if (_hasReplies(current) && !_isFromMoonSaved(current)) {
      actions.add(
        ResponsiveFooterAction(
          asset: "assets/icons/reply.svg",
          semanticsLabel: 'Reply',
          size: iconSize,
          splashRadius: 25,
          tooltip: 'Vedi risposte',
          onPressed: () {},
        ),
      );
    } else if (_isFromMoonSaved(current)) {
      actions.add(
        ResponsiveFooterAction(
          asset: "assets/icons/reply.svg",
          semanticsLabel: 'Rispondi',
          colorFilter: const ColorFilter.mode(
            HonooColor.onBackground,
            BlendMode.srcIn,
          ),
          size: iconSize,
          splashRadius: 25,
          tooltip: 'Rispondi',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReplyHonooPage(
                  originalHonoo: current,
                  initialHintText: 'Scrivi la tua risposta...',
                  initialImageHint: 'Aggiungi un’immagine (opzionale)',
                ),
              ),
            );
          },
        ),
      );
    }

    actions.add(
      ResponsiveFooterAction(
        asset: "assets/icons/cancella.svg",
        semanticsLabel: 'Cancella',
        colorFilter: const ColorFilter.mode(
          HonooColor.onBackground,
          BlendMode.srcIn,
        ),
        size: iconSize,
        splashRadius: 25,
        tooltip: 'Cancella',
        onPressed: () async {
          final bool? confirmed = await showHonooDeleteDialog(
            context,
            target: HonooDeletionTarget.honoo,
          );
          if (!mounted) return;
          if (confirmed != true) return;

          final String? id = (current.dbId ?? current.id) as String?;
          if (id == null || id.isEmpty) {
            showHonooToast(context,
                message: 'Impossibile cancellare: id mancante.');
            return;
          }

          await ctrl.deleteHonooById(id);
          if (!mounted) return;
          showHonooToast(context, message: 'honoo eliminato.');
        },
      ),
    );

    return ResponsiveFooterBar(
      useSafeArea: false,
      bottomPadding: bottomPadding,
      desiredGap: gap,
      minGap: 16,
      height: iconSize,
      actions: actions,
    );
  }

  Widget _footerForHinoo(
    _HinooRow? current, {
    required double iconSize,
    required double gap,
    required double bottomPadding,
  }) {
    if (current == null) {
      return _footerForHonoo(
        null,
        iconSize: iconSize,
        gap: gap,
        bottomPadding: bottomPadding,
      );
    }

    final draft = current.draft;
    final bool isPersonal = draft.type == HinooType.personal;
    final bool isFromMoonSaved = draft.type == HinooType.moon;
    final actions = <ResponsiveFooterAction>[
      ResponsiveFooterAction(
        asset: "assets/icons/home.svg",
        semanticsLabel: 'Home',
        colorFilter: const ColorFilter.mode(
          HonooColor.onBackground,
          BlendMode.srcIn,
        ),
        size: iconSize,
        splashRadius: 25,
        tooltip: 'Home',
        onPressed: _goHome,
      ),
    ];

    if (isPersonal && !isFromMoonSaved) {
      actions.add(
        ResponsiveFooterAction(
          asset: "assets/icons/moon.svg",
          semanticsLabel: 'Luna',
          colorFilter: const ColorFilter.mode(
            HonooColor.onBackground,
            BlendMode.srcIn,
          ),
          size: iconSize,
          splashRadius: 25,
          tooltip: 'Spedisci sulla Luna',
          onPressed: () async {
            try {
              final result = await _hinooController.sendToMoon(draft);
              if (!mounted) return;
              final text = result == HinooMoonResult.published
                  ? 'hinoo spedito sulla Luna.'
                  : 'hinoo già presente sulla Luna.';
              showHonooToast(context, message: text);
            } catch (e) {
              if (!mounted) return;
              showHonooToast(context, message: 'Errore: $e');
            }
          },
        ),
      );
    }

    actions.add(
      ResponsiveFooterAction(
        asset: "assets/icons/cancella.svg",
        semanticsLabel: 'Cancella',
        colorFilter: const ColorFilter.mode(
          HonooColor.onBackground,
          BlendMode.srcIn,
        ),
        size: iconSize,
        splashRadius: 25,
        tooltip: 'Cancella',
        onPressed: () => _deleteHinoo(current),
      ),
    );

    return ResponsiveFooterBar(
      useSafeArea: false,
      bottomPadding: bottomPadding,
      desiredGap: gap,
      minGap: 16,
      height: iconSize,
      actions: actions,
    );
  }

  Widget _footerForItem(
    _ChestItem? item, {
    required double iconSize,
    required double gap,
    required double bottomPadding,
  }) {
    if (item == null) {
      return _footerForHonoo(
        null,
        iconSize: iconSize,
        gap: gap,
        bottomPadding: bottomPadding,
      );
    }
    return item.when(
      honoo: (h) => _footerForHonoo(
        h,
        iconSize: iconSize,
        gap: gap,
        bottomPadding: bottomPadding,
      ),
      hinoo: (row) => _footerForHinoo(
        row,
        iconSize: iconSize,
        gap: gap,
        bottomPadding: bottomPadding,
      ),
    );
  }

  Future<void> _deleteHinoo(_HinooRow current) async {
    final bool? confirmed = await showHonooDeleteDialog(
      context,
      target: HonooDeletionTarget.hinoo,
    );
    if (confirmed != true) return;

    try {
      final client = SupabaseProvider.client;
      await client.from('hinoo').delete().eq('id', current.id);

      if (!mounted) return;
      setState(() {
        _hinoo = _hinoo.where((r) => r.id != current.id).toList();
        _rebuildItems();
      });
      showHonooToast(context, message: 'hinoo eliminato.');
    } catch (e) {
      if (!mounted) return;
      showHonooToast(context, message: 'Errore durante l\'eliminazione: $e');
    }
  }

  // =========================
  // DOWNLOAD (operazione C)
  // =========================

  Future<void> _handleDownloadForItem(
      _ChestItem item, GlobalKey repaintKey) async {
    final user = SupabaseProvider.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (_) => const HonooConfirmDialog(
          title: 'Devi accedere',
          message:
              'Per scaricare questo contenuto, devi fare prima il log in. Vuoi andare alla pagina di login?',
          confirmLabel: 'Vai al login',
        ),
      );
      return;
    }

    // Minimo contenuto (solo Hinoo)
    final bool okMin = item.when(
      honoo: (_) => true,
      hinoo: (row) {
        final int totalChars = row.draft.pages
            .map((p) => (p.text ?? '').trim().length)
            .fold<int>(0, (a, b) => a + b);
        return totalChars >= 1;
      },
    );

    if (!okMin) {
      if (!mounted) return;
      showHonooToast(context,
          message: 'Scrivi almeno 1 carattere prima di scaricare');
      return;
    }

    await _downloadFromBoundary(
      repaintKey: repaintKey,
      baseName: item.when(
        honoo: (_) => 'honoo',
        hinoo: (_) => 'hinoo',
      ),
    );
  }

  Future<void> _downloadFromBoundary({
    required GlobalKey repaintKey,
    required String baseName,
  }) async {
    try {
      final RenderRepaintBoundary? boundary = repaintKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('Impossibile scaricare: boundary non trovata.');
      }

      // Qualità: mira a ~1920px in altezza
      double pixelRatio = 3.0;
      final ui.Size logicalSize = boundary.size;
      if (logicalSize.height > 0) {
        const double targetHeight = 1920.0;
        final double ratioH = targetHeight / logicalSize.height;
        if (ratioH.isFinite && ratioH > 0) pixelRatio = ratioH;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List? bytes = byteData?.buffer.asUint8List();

      if (bytes == null || bytes.isEmpty) {
        throw Exception('PNG vuoto o nullo.');
      }

      final DownloadSaver saver = getDownloadSaver();
      final String filename =
          '${baseName}_${DateTime.now().millisecondsSinceEpoch}.png';

      final String message = await saver.save(
        [DownloadImage(filename: filename, bytes: bytes)],
        message: 'creato con honoo',
      );

      if (!mounted) return;
      showHonooToast(context,
          message: message.isNotEmpty ? message : 'Download avviato.');
    } catch (e) {
      if (!mounted) return;
      showHonooToast(context, message: 'Errore download: $e');
    }
  }

  // =========================
  // ITEM UI (overlay position per ciò che vedi)
  // =========================

  Widget _buildChestItem(
    _ChestItem item,
    double availableCenterH,
    double targetMaxW,
    HonooBuilderMetrics honooMetrics,
  ) {
    final String identity = item.when(
      honoo: (h) {
        final String? dbId = h.dbId;
        final int localId = h.id;
        final String fallback = localId != 0
            ? localId.toString()
            : item.createdAt.toIso8601String();
        return 'honoo_${dbId ?? fallback}';
      },
      hinoo: (row) => 'hinoo_${row.id}',
    );

    final GlobalKey repaintKey = _keyFor(identity);
    final bool isHonoo = item.honoo != null;

    final double cardW = isHonoo
        ? honooMetrics.width
        : targetMaxW.clamp(0.0, 360.0);
    final double cardMaxH = isHonoo ? honooMetrics.height : availableCenterH;

    final bool isDesktop = MediaQuery.of(context).size.width >= 900;

    final double rightPad = isDesktop
        ? (isHonoo ? honooRightDesktop : hinooRightDesktop)
        : rightMobile;

    final double topPad =
        isDesktop ? topDesktop : (isHonoo ? honooTopMobile : hinooTopMobile);

    final Widget content = item.when(
      honoo: (h) => HonooThreadView(root: h),
      hinoo: (row) => HinooViewer(
        draft: row.draft,
        maxHeight: availableCenterH,
        maxWidth: cardW,
      ),
    );

    // ✅ La "card reale" (bianca) è questa:
    final Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: cardW,
        // niente height fissa qui!
        child: RepaintBoundary(
          key: repaintKey,
          child: content,
        ),
      ),
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: KeyedSubtree(
        key: ValueKey(identity),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
                  cardMaxH, // ✅ limite massimo, ma altezza reale libera
              maxWidth: cardW,
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge, // 🔒 sempre dentro
              children: [
                card,
                Positioned(
                  top: topPad,
                  right: rightPad,
                  child: Material(
                    color: Colors.transparent,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            tooltip: 'download',
                            icon: const Icon(
                              Icons.download_outlined,
                              size: 22,
                              color: Colors.white,
                            ),
                            onPressed: () =>
                                _handleDownloadForItem(item, repaintKey),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            splashRadius: 17,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const headerH = 52.0;

    final double lunaReserve = LunaFissa.reserveTopPadding(context);
    final double extraTop = (lunaReserve - headerH);
    final double contentTopPadding = extraTop > 0 ? extraTop : 0;

    return Scaffold(
      backgroundColor: HonooColor.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([ctrl.isLoading, ctrl.version]),
          builder: (context, _) {
            _rebuildItems();
            final _ChestItem? current =
                _items.isEmpty ? null : _items[_currentIndex];

            return LayoutBuilder(
              builder: (context, constraints) {
                final availH = constraints.maxHeight;

                final double targetMaxW =
                    ResponsiveLayout.contentMaxWidth(constraints.maxWidth);
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

                final double availableCenterH =
                    (availH - headerH - contentTopPadding - footerReserved)
                        .clamp(0.0, double.infinity);
                final HonooBuilderMetrics honooMetrics =
                    ResponsiveLayout.honooBuilderMetrics(
                  availableHeight: availableCenterH,
                  maxWidth: targetMaxW,
                  mode: layoutMode,
                );

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
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
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              0,
                              contentTopPadding,
                              0,
                              20,
                            ),
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 90),
                                curve: Curves.easeOutCubic,
                                constraints:
                                    BoxConstraints(maxWidth: targetMaxW),
                                child: SizedBox(
                                  height: availableCenterH,
                                  width: double.infinity,
                                  child: () {
                                    if (ctrl.isLoading.value ||
                                        _isHinooLoading) {
                                      return const Center(
                                        child:
                                            LoadingSpinner(color: Colors.white),
                                      );
                                    }

                                    if (_items.isEmpty) {
                                      return Center(
                                        child: Text(
                                          'Nessun contenuto nello scrigno',
                                          style: GoogleFonts.libreFranklin(
                                            color: HonooColor.onBackground,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      );
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: cs.CarouselSlider.builder(
                                        itemCount: _items.length,
                                        options: cs.CarouselOptions(
                                          height: availableCenterH,
                                          viewportFraction: 1.0,
                                          enableInfiniteScroll: false,
                                          padEnds: true,
                                          enlargeCenterPage: false,
                                          scrollPhysics:
                                              const BouncingScrollPhysics(),
                                          onPageChanged: (i, _) =>
                                              setState(() => _currentIndex = i),
                                        ),
                                        itemBuilder: (context, index, realIdx) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16),
                                            child: _buildChestItem(
                                              _items[index],
                                              availableCenterH,
                                              targetMaxW,
                                              honooMetrics,
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  }(),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: footerTopSpacing),
                        _footerForItem(
                          current,
                          iconSize: footerIconSize,
                          gap: footerGap,
                          bottomPadding: footerBottomSpacing,
                        ),
                      ],
                    ),
                    const LunaFissa(),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// =========================
// MODELS (local)
// =========================

class _ChestItem {
  final Honoo? honoo;
  final _HinooRow? hinoo;
  final DateTime createdAt;

  const _ChestItem._({this.honoo, this.hinoo, required this.createdAt});

  factory _ChestItem.honoo(Honoo h, DateTime createdAt) =>
      _ChestItem._(honoo: h, createdAt: createdAt);

  factory _ChestItem.hinoo(_HinooRow row) =>
      _ChestItem._(hinoo: row, createdAt: row.createdAt);

  T when<T>({
    required T Function(Honoo h) honoo,
    required T Function(_HinooRow row) hinoo,
  }) {
    if (this.honoo != null) return honoo(this.honoo!);
    return hinoo(this.hinoo!);
  }
}

class _HinooRow {
  final String id;
  final HinooDraft draft;
  final DateTime createdAt;

  const _HinooRow({
    required this.id,
    required this.draft,
    required this.createdAt,
  });
}
