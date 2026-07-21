import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:honoo/Services/supabase_provider.dart';
import 'package:honoo/Services/chest_repository.dart';
import 'package:honoo/Services/download_capture_service.dart';
import 'package:honoo/Services/chest_hint_service.dart';

import '../Controller/honoo_controller.dart';
import '../Controller/hinoo_controller.dart';
import '../Controller/chest_organizer.dart';
import '../Controller/chest_controller.dart';
import '../Entities/honoo.dart';
import '../Entities/hinoo.dart';
import '../Entities/chest_item.dart';
import '../Entities/hinoo_thread_entry.dart';

import '../Utility/honoo_colors.dart';
import '../Utility/responsive_layout.dart';
import '../Utility/network_image_prefetch.dart';

import '../Widgets/honoo_dialogs.dart';
import '../Widgets/loading_spinner.dart';
import '../Widgets/honoo_app_title.dart';
import '../Widgets/luna_fissa.dart';
import '../Widgets/chest_footer.dart';
import '../Widgets/chest_item_view.dart';
import '../Widgets/chest_info_dialog.dart';
import '../Widgets/desktop_carousel_arrows.dart';
import '../UI/thread_layout_scaffold.dart';

import 'reply_honoo_page.dart';
import 'new_hinoo_page.dart';
import 'home_page.dart';
import 'placeholder_page.dart';
import 'package:honoo/Entities/conversation_entry.dart';
import 'package:honoo/Entities/conversation_link.dart';

class ChestPage extends StatefulWidget {
  const ChestPage({
    super.key,
    this.focusReplies = false,
    this.focusConversationId,
    this.highlightLatest = false,
  });

  final bool focusReplies;
  final String? focusConversationId;
  final bool highlightLatest;

  @override
  State<ChestPage> createState() => _ChestPageState();
}

class _ChestPageState extends State<ChestPage> {
  // Conversational mode support
  // Structural only: no layout/axis/animation changes.
  // Two modes: normal chest vs conversation view fed into the same builder.
  ChestMode _mode = ChestMode.normal;
  String? _activeConversationId;
  int? _previousIndexBeforeConversation;
  // removed unused selected conversation index (not needed for rendering)

  final HonooController ctrl = HonooController();
  final HinooController _hinooController = HinooController();
  late final ChestRepository _chestRepository = ChestRepository();
  late final ChestController _chestController =
      ChestController(repository: _chestRepository);
  final DownloadCaptureService _downloadCaptureService =
      DownloadCaptureService();
  final ChestHintService _chestHintService = ChestHintService();

  int _currentIndex = 0;
  int _conversationRefreshToken = 0;
  // Data lists for normal vs conversation mode
  List<ChestItem> _itemsNormal = const [];
  List<ChestHinooItem> get _hinoo => _chestController.value.hinoo;
  Map<String, DateTime> get _honooLatestReplies =>
      _chestController.value.honooLatestReplies;
  Map<String, DateTime> get _hinooLatestReplies =>
      _chestController.value.hinooLatestReplies;
  Map<String, List<HinooThreadEntry>> get _hinooRepliesByRoot =>
      _chestController.value.hinooRepliesByRoot;
  ConversationEntry? _selectedConvEntry;
  bool get _isHinooLoading => _chestController.value.isHinooLoading;
  final cs.CarouselController _carouselController = cs.CarouselController();
  // Performance guard: avoid redundant regrouping when inputs haven't changed
  String? _lastRebuildSignature;
  int _rebuildCalls = 0; // debug counter

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
    _chestController.addListener(_onChestStateChanged);
    _loadAll();
    _maybeShowScrignoHint();
    final uid = SupabaseProvider.client.auth.currentUser?.id;
    if (uid != null) _chestController.startRealtime(uid);
  }

  @override
  void dispose() {
    _chestController.removeListener(_onChestStateChanged);
    _chestController.dispose();
    super.dispose();
  }

  void _onChestStateChanged() {
    if (!mounted) return;
    setState(_rebuildItems);
  }

  Future<void> _maybeShowScrignoHint() async {
    if (!await _chestHintService.shouldShow()) return;
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showHonooMessageDialog(
        context,
        title: 'Scrigno',
        message: 'Clicca su Info per la spiegazione.',
        duration: const Duration(milliseconds: 2200),
      );
    });
  }

  void _showScrignoInfo() {
    showChestInfoDialog(context);
  }

  Future<void> _loadAll() async {
    try {
      await ctrl.loadChest();
    } catch (_) {}
    final uid = SupabaseProvider.client.auth.currentUser?.id;
    if (uid == null) {
      _chestController.completeWithoutUser();
      return;
    }
    await _chestController.loadHinoo(uid);
    await _chestController.refreshReplies(uid);
  }

  String _stableIdOf(ChestItem it) {
    return it.when(
      honoo: (h) => (h.dbId ?? ''),
      hinoo: (row) => row.id,
    );
  }

  void _rebuildItems() {
    // Build a lightweight signature of inputs that affect list construction
    final String sig = [
      ctrl.version.value.toString(),
      _hinoo.length.toString(),
      _honooLatestReplies.length.toString(),
      _hinooLatestReplies.length.toString(),
      _hinooRepliesByRoot.length.toString(),
      widget.focusConversationId ?? '',
      widget.focusReplies ? '1' : '0',
      widget.highlightLatest ? '1' : '0',
      _mode.name,
      _activeConversationId ?? '',
    ].join('|');
    assert(() {
      _rebuildCalls++;
      debugPrint('ChestPage._rebuildItems() #$_rebuildCalls sig=$sig');
      return true;
    }());
    if (_lastRebuildSignature == sig) {
      return; // No input change; skip expensive regrouping
    }
    _lastRebuildSignature = sig;
    final honooItems = ctrl.personal.map<ChestItem>((h) {
      // Use updated_at when available to satisfy ordering by last activity/edit
      final DateTime dt = DateTime.tryParse(h.updatedAt) ??
          DateTime.tryParse(h.createdAt) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return ChestItem.honoo(h, dt);
    }).toList();

    final hinooItems =
        _hinoo.map<ChestItem>((r) => ChestItem.hinoo(r)).toList();

    final items = [...honooItems, ...hinooItems];
    final organization = ChestOrganizer.organize<ChestItem>(
      items: items,
      createdAtOf: (item) => item.createdAt,
      stableIdOf: _stableIdOf,
      latestReplyOf: (item) => item.when(
        honoo: (h) => _honooLatestReplies[h.dbId ?? ''],
        hinoo: (row) => _hinooLatestReplies[row.id],
      ),
      conversationIdOf: _convIdOfItem,
    );
    _itemsNormal = organization.items;
    final bool hasConversationItems = organization.conversationItemCount > 0;

    if (_mode == ChestMode.normal && widget.focusConversationId != null) {
      final idx = _itemsNormal.indexWhere((it) {
        final String? cid = it.when(
          honoo: (h) => h.conversationId,
          hinoo: (row) => row.conversationId ?? row.draft.conversationId,
        );
        return cid == widget.focusConversationId;
      });
      if (idx >= 0) {
        _currentIndex = idx;
      } else if (widget.focusReplies && hasConversationItems) {
        _currentIndex = 0;
      }
    } else if (_mode == ChestMode.normal &&
        widget.focusReplies &&
        hasConversationItems) {
      _currentIndex = 0;
    } else if (_mode == ChestMode.normal &&
        _currentIndex >= _itemsNormal.length) {
      _currentIndex = _itemsNormal.isEmpty ? 0 : _itemsNormal.length - 1;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _prefetchChestFrom(_currentIndex);
    });
  }

  void _prefetchChestFrom(int index) {
    if (_itemsNormal.isEmpty) return;
    final end = (index + 2).clamp(0, _itemsNormal.length);
    final urls = <String?>[];
    for (final item in _itemsNormal.sublist(index, end)) {
      item.when(
        honoo: (honoo) => urls.addAll(honooImageUrls(honoo)),
        hinoo: (hinoo) => urls.addAll(hinooImageUrls(hinoo.draft)),
      );
    }
    prefetchImageUrls(context, urls);
  }

  // conversation loading removed — UnifiedThreadView handles it

  String? _convIdOfItem(ChestItem it) => it.when(
        honoo: (h) => h.conversationId,
        hinoo: (row) => row.conversationId ?? row.draft.conversationId,
      );

  // ignore: unused_element
  void _exitConversation() {
    setState(() {
      _mode = ChestMode.normal;
      _activeConversationId = null;
      if (_previousIndexBeforeConversation != null) {
        _currentIndex = _previousIndexBeforeConversation!.clamp(
          0,
          _itemsNormal.isEmpty ? 0 : _itemsNormal.length - 1,
        );
      }
    });
  }

  Widget _footerForItem(
    ChestItem? item, {
    required double iconSize,
    required double gap,
    required double bottomPadding,
  }) {
    return ChestFooter(
      item: item,
      selectedConversationEntry: _selectedConvEntry,
      currentUserId: SupabaseProvider.client.auth.currentUser?.id,
      iconSize: iconSize,
      gap: gap,
      bottomPadding: bottomPadding,
      onHome: _goHome,
      onInfo: _showScrignoInfo,
      onSendHonooToMoon: _sendHonooToMoon,
      onReplyToHonoo: _showReplyChoiceForHonoo,
      onDeleteHonoo: _deleteHonoo,
      onSendHinooToMoon: _sendHinooToMoon,
      onReplyToHinoo: _showReplyChoiceForHinoo,
      onDeleteHinoo: _deleteHinoo,
      onSendConversationEntryToMoon: _sendConversationEntryToMoon,
    );
  }

  Future<void> _sendHonooToMoon(Honoo honoo) async {
    final ok = await HonooController().sendToMoon(honoo);
    if (!mounted) return;
    showHonooToast(
      context,
      message: ok
          ? "L'honoo è anche sulla Luna."
          : "L'honoo era già presente sulla Luna.",
    );
  }

  Future<void> _deleteHonoo(Honoo honoo) async {
    final confirmed = await showHonooDeleteDialog(
      context,
      target: HonooDeletionTarget.honoo,
    );
    if (!mounted || confirmed != true) return;
    final String? id = (honoo.dbId ?? honoo.id) as String?;
    if (id == null || id.isEmpty) {
      showHonooToast(context, message: 'Impossibile cancellare: id mancante.');
      return;
    }
    await ctrl.deleteHonooById(id);
    if (!mounted) return;
    showHonooToast(context, message: 'honoo eliminato.');
  }

  Future<void> _sendHinooToMoon(ChestHinooItem hinoo) async {
    try {
      final result = await _hinooController.sendToMoon(hinoo.draft);
      if (!mounted) return;
      final text = result == HinooMoonResult.published
          ? "L'hinoo è anche sulla Luna."
          : "L'hinoo era già presente sulla Luna.";
      showHonooToast(context, message: text);
    } catch (error) {
      if (!mounted) return;
      showHonooToast(context, message: 'Errore: $error');
    }
  }

  Future<void> _sendConversationEntryToMoon(ConversationEntry entry) async {
    try {
      if (entry.kind == ConversationEntryKind.honoo) {
        await _sendHonooToMoon(entry.honoo!);
      } else {
        final result = await _hinooController.sendToMoon(entry.hinoo!);
        if (!mounted) return;
        final text = result == HinooMoonResult.published
            ? "L'hinoo è anche sulla Luna."
            : "L'hinoo era già presente sulla Luna.";
        showHonooToast(context, message: text);
      }
    } catch (error) {
      if (!mounted) return;
      showHonooToast(context, message: 'Errore: $error');
    }
  }

  Future<void> _deleteHinoo(ChestHinooItem current) async {
    final bool? confirmed = await showHonooDeleteDialog(
      context,
      target: HonooDeletionTarget.hinoo,
    );
    if (confirmed != true) return;

    try {
      await _chestRepository.deleteHinoo(current.id);

      if (!mounted) return;
      _chestController.removeHinoo(current.id);
      showHonooToast(context, message: 'hinoo eliminato.');
    } catch (e) {
      if (!mounted) return;
      showHonooToast(context, message: 'Errore durante l\'eliminazione: $e');
    }
  }

  Future<void> _showReplyChoiceForHonoo(Honoo current) async {
    final _ReplyChoice? choice = await _showReplyChoice();
    if (choice == null || !mounted) return;
    if (choice == _ReplyChoice.honoo) {
      final result = await Navigator.push<Object?>(
        context,
        MaterialPageRoute(
          builder: (context) => ReplyHonooPage(
            originalHonoo: current,
            initialHintText: 'Scrivi la tua risposta...',
            initialImageHint: 'Aggiungi un’immagine (opzionale)',
            returnToPreviousOnAnswer: true,
          ),
        ),
      );
      _refreshConversationInPlace(result is String ? result : null);
    } else {
      final String? replyTo = current.dbId;
      if (replyTo == null || replyTo.isEmpty) return;
      final link = ConversationLink.fromParent(
        parentId: replyTo,
        parentConversationId: current.conversationId,
        recipientId: current.userId,
      );
      final result = await Navigator.push<Object?>(
        context,
        MaterialPageRoute(
          builder: (context) => NewHinooPage(
            forcedType: HinooType.answer,
            recipientTag: link.recipientId,
            replyTo: link.replyTo,
            conversationId: link.conversationId,
            returnToPreviousOnAnswer: true,
          ),
        ),
      );
      _refreshConversationInPlace(result is String ? result : null);
    }
  }

  Future<void> _showReplyChoiceForHinoo(ChestHinooItem current) async {
    final _ReplyChoice? choice = await _showReplyChoice();
    if (choice == null || !mounted) return;
    if (choice == _ReplyChoice.honoo) {
      final String recipient =
          current.ownerId ?? current.draft.recipientTag ?? '';
      if (recipient.isEmpty) return;
      final link = ConversationLink.fromParent(
        parentId: current.id,
        parentConversationId:
            current.conversationId ?? current.draft.conversationId,
        recipientId: recipient,
      );
      final result = await Navigator.push<Object?>(
        context,
        MaterialPageRoute(
          builder: (context) => ReplyHonooPage(
            originalHonoo: Honoo(
              0,
              '',
              '',
              current.createdAt.toIso8601String(),
              current.createdAt.toIso8601String(),
              recipient,
              HonooType.personal,
              link.replyTo,
              link.recipientId,
            )
              ..dbId = link.replyTo
              ..conversationId = link.conversationId,
            initialHintText: 'Scrivi la tua risposta...',
            initialImageHint: 'Aggiungi un’immagine (opzionale)',
            returnToPreviousOnAnswer: true,
          ),
        ),
      );
      _refreshConversationInPlace(result is String ? result : null);
    } else {
      final String recipient =
          current.ownerId ?? current.draft.recipientTag ?? '';
      if (recipient.isEmpty) return;
      final link = ConversationLink.fromParent(
        parentId: current.id,
        parentConversationId:
            current.conversationId ?? current.draft.conversationId,
        recipientId: recipient,
      );
      final result = await Navigator.push<Object?>(
        context,
        MaterialPageRoute(
          builder: (context) => NewHinooPage(
            forcedType: HinooType.answer,
            recipientTag: link.recipientId,
            replyTo: link.replyTo,
            conversationId: link.conversationId,
            returnToPreviousOnAnswer: true,
          ),
        ),
      );
      _refreshConversationInPlace(result is String ? result : null);
    }
  }

  void _refreshConversationInPlace(String? conversationId) {
    if (!mounted || conversationId == null || conversationId.isEmpty) return;
    setState(() {
      _conversationRefreshToken++;
    });
  }

  Future<_ReplyChoice?> _showReplyChoice() {
    return showDialog<_ReplyChoice>(
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
                  onPressed: () =>
                      Navigator.of(context).pop(_ReplyChoice.honoo),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
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
                  onPressed: () =>
                      Navigator.of(context).pop(_ReplyChoice.hinoo),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
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
  }

  // =========================
  // DOWNLOAD (operazione C)
  // =========================

  Future<void> _handleDownloadForItem(
      ChestItem item, GlobalKey repaintKey) async {
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
            .map((p) => p.text.trim().length)
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

    try {
      final message = await _downloadCaptureService.captureAndSave(
        repaintKey: repaintKey,
        baseName: item.when(
          honoo: (_) => 'honoo',
          hinoo: (_) => 'hinoo',
        ),
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
    ChestItem item,
    double availableCenterH,
    double targetMaxW,
    HonooBuilderMetrics honooMetrics, {
    bool isActive = false,
  }) {
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
    return ChestItemView(
      item: item,
      availableHeight: availableCenterH,
      maxWidth: targetMaxW,
      honooMetrics: honooMetrics,
      repaintKey: repaintKey,
      hinooRepliesByRoot: _hinooRepliesByRoot,
      isNormalMode: _mode == ChestMode.normal,
      isActive: isActive,
      highlightLatest: widget.highlightLatest,
      focusConversationId: widget.focusConversationId,
      onSelectConversationEntry: (entry) {
        setState(() => _selectedConvEntry = entry);
      },
      onDownload: () => _handleDownloadForItem(item, repaintKey),
      conversationRefreshToken: _conversationRefreshToken,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([ctrl.isLoading, ctrl.version]),
      builder: (context, _) {
        _rebuildItems();
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
          overlayBuilder: (ctx, mode) => const LunaFissa(),
          bodyBuilder: (ctx, viewW, availableH, layoutMode) {
            final HonooBuilderMetrics honooMetrics =
                ResponsiveLayout.honooBuilderMetrics(
              availableHeight: availableH,
              maxWidth: viewW,
              mode: layoutMode,
            );
            if (ctrl.isLoading.value || _isHinooLoading) {
              return const Center(child: LoadingSpinner(color: Colors.white));
            }
            final items = _itemsNormal;
            if (items.isEmpty) {
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
            // Use PageScrollPhysics to avoid gesture conflicts with nested vertical carousels
            const horizPhysics = PageScrollPhysics();
            final slider = cs.CarouselSlider.builder(
              carouselController: _carouselController,
              itemCount: items.length,
              options: cs.CarouselOptions(
                height: availableH,
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
                padEnds: false,
                enlargeCenterPage: false,
                disableCenter: true,
                scrollPhysics: horizPhysics,
                onPageChanged: (i, _) {
                  setState(() => _currentIndex = i);
                  _prefetchChestFrom(i);
                },
              ),
              itemBuilder: (context, index, realIdx) {
                final bool isActive = _currentIndex == index;
                return _buildChestItem(
                  items[index],
                  availableH,
                  viewW,
                  honooMetrics,
                  isActive: isActive,
                );
              },
            );
            // Il reveal della conversazione viene gestito da
            // UnifiedThreadView usando i messaggi reali del thread. Qui ogni
            // conversazione occupa ormai una sola slide del carosello.
            final bool isDesktop = layoutMode == ResponsiveLayoutMode.desktop ||
                layoutMode == ResponsiveLayoutMode.wideDesktop ||
                layoutMode == ResponsiveLayoutMode.largeDesktop;
            if (!isDesktop || items.length <= 1) {
              return slider;
            }
            return DesktopCarouselArrows(
              canPrev: _currentIndex > 0,
              canNext: _currentIndex < items.length - 1,
              onPrev: () => _carouselController.animateToPage(
                (_currentIndex - 1).clamp(0, items.length - 1),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
              ),
              onNext: () => _carouselController.animateToPage(
                (_currentIndex + 1).clamp(0, items.length - 1),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
              ),
              arrowColor: Colors.white,
              child: slider,
            );
          },
          footerBuilder: (ctx, mode, footerIconSize, footerGap,
              footerTopSpacing, footerBottomSpacing) {
            final items = _itemsNormal;
            final ChestItem? current =
                items.isEmpty ? null : items[_currentIndex];
            return _footerForItem(
              current,
              iconSize: footerIconSize,
              gap: footerGap,
              bottomPadding: footerBottomSpacing,
            );
          },
        );
      },
    );
  }
}

enum _ReplyChoice { honoo, hinoo }

// Public enum for Chest mode selection (local to this file usage)
enum ChestMode {
  normal,
  conversation,
}
