import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:honoo/Services/supabase_provider.dart';
import 'package:honoo/Services/chest_repository.dart';
import 'package:honoo/Services/download_capture_service.dart';
import 'package:honoo/Services/chest_hint_service.dart';
import 'package:honoo/Services/duplication_result.dart';

import '../Controller/honoo_controller.dart';
import '../Controller/hinoo_controller.dart';
import '../Controller/chest_organizer.dart';
import '../Controller/chest_controller.dart';
import '../Entities/honoo.dart';
import '../Entities/hinoo.dart';
import '../Entities/chest_item.dart';
import '../Entities/hinoo_thread_entry.dart';
import '../Entities/reply_navigation_result.dart';

import '../Utility/honoo_colors.dart';
import '../Utility/responsive_layout.dart';
import '../Utility/network_image_prefetch.dart';
import '../Utility/replies_seen_tracker.dart';

import '../Widgets/honoo_dialogs.dart';
import '../Widgets/gallery_save_dialog.dart';
import '../Widgets/loading_spinner.dart';
import '../Widgets/honoo_app_title.dart';
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
    this.focusReplyId,
  });

  final bool focusReplies;
  final String? focusConversationId;
  final bool highlightLatest;
  final String? focusReplyId;

  @override
  State<ChestPage> createState() => _ChestPageState();
}

class _ChestPageState extends State<ChestPage> with WidgetsBindingObserver {
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
  late final ChestController _chestController = ChestController(
    repository: _chestRepository,
  );
  final DownloadCaptureService _downloadCaptureService =
      DownloadCaptureService();
  final ChestHintService _chestHintService = ChestHintService();

  int _currentIndex = 0;
  bool _didApplyInitialFocus = false;
  bool _initialLoadCompleted = false;
  int _conversationRefreshToken = 0;
  String? _pendingRevealEntryId;
  Object? _honooLoadError;
  bool _isMutating = false;
  bool _isReconciling = false;
  bool _reconcilePending = false;
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
  final cs.CarouselSliderController _carouselController =
      cs.CarouselSliderController();
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

  void _selectConversationEntry(ConversationEntry entry) {
    setState(() => _selectedConvEntry = entry);
    final currentUserId = SupabaseProvider.client.auth.currentUser?.id;
    final isReply =
        entry.honoo?.type == HonooType.answer ||
        entry.hinoo?.type == HinooType.answer;
    if (!isReply ||
        currentUserId == null ||
        entry.ownerId == currentUserId ||
        entry.createdAt.millisecondsSinceEpoch <= 0) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        RepliesSeenTracker.markAt(entry.createdAt, userId: currentUserId),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _pendingRevealEntryId = widget.focusReplyId;
    WidgetsBinding.instance.addObserver(this);
    _chestController.addListener(_onChestStateChanged);
    unawaited(_initialize());
    _maybeShowScrignoHint();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chestController.removeListener(_onChestStateChanged);
    _chestController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(_resumeRealtimeAndReconcile());
  }

  Future<void> _resumeRealtimeAndReconcile() async {
    await _reconcileAll();
    if (!mounted) return;
    final uid = SupabaseProvider.client.auth.currentUser?.id;
    if (uid != null) {
      _chestController.startRealtime(uid, onPeriodicReconcile: _reconcileAll);
    }
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
      if (mounted) setState(() => _honooLoadError = null);
      try {
        await ctrl.loadChest();
      } catch (error) {
        if (mounted) setState(() => _honooLoadError = error);
      }
      final uid = SupabaseProvider.client.auth.currentUser?.id;
      if (uid == null) {
        _chestController.completeWithoutUser();
        return;
      }
      await _chestController.loadHinoo(uid);
      await _chestController.refreshReplies(uid);
    } finally {
      if (!_initialLoadCompleted && mounted) {
        setState(() {
          _initialLoadCompleted = true;
          _lastRebuildSignature = null;
          _rebuildItems();
        });
      }
    }
  }

  Future<void> _initialize() async {
    await _reconcileAll();
    if (!mounted) return;
    final uid = SupabaseProvider.client.auth.currentUser?.id;
    if (uid != null) {
      _chestController.startRealtime(uid, onPeriodicReconcile: _reconcileAll);
    }
  }

  Future<void> _reconcileAll() async {
    if (_isReconciling) {
      _reconcilePending = true;
      return;
    }
    _isReconciling = true;
    try {
      do {
        _reconcilePending = false;
        await _loadAll();
      } while (_reconcilePending && mounted);
    } finally {
      _isReconciling = false;
    }
  }

  Object? get _loadError =>
      _honooLoadError ??
      _chestController.value.hinooError ??
      _chestController.value.replyError;

  String _stableIdOf(ChestItem it) {
    return it.when(honoo: (h) => (h.dbId ?? ''), hinoo: (row) => row.id);
  }

  String _slideIdentity(ChestItem item) {
    final conversationId = _convIdOfItem(item);
    if (conversationId != null && conversationId.isNotEmpty) {
      return 'conversation:$conversationId';
    }
    return item.when(
      honoo: (honoo) => 'honoo:${honoo.dbId ?? honoo.id}',
      hinoo: (hinoo) => 'hinoo:${hinoo.id}',
    );
  }

  void _rebuildItems() {
    final previousIdentity =
        _itemsNormal.isNotEmpty &&
            _currentIndex >= 0 &&
            _currentIndex < _itemsNormal.length
        ? _slideIdentity(_itemsNormal[_currentIndex])
        : null;
    // Build a lightweight signature of inputs that affect list construction
    final String sig = [
      ctrl.version.value.toString(),
      ..._hinoo.map(
        (item) =>
            '${item.id}:${item.createdAt.toIso8601String()}:${item.conversationId ?? item.draft.conversationId ?? ''}',
      ),
      ..._sortedActivitySignature('honoo', _honooLatestReplies),
      ..._sortedActivitySignature('hinoo', _hinooLatestReplies),
      ..._sortedReplySignature(),
      widget.focusConversationId ?? '',
      widget.focusReplies ? '1' : '0',
      widget.highlightLatest ? '1' : '0',
      _initialLoadCompleted ? 'loaded' : 'loading',
      _pendingRevealEntryId ?? '',
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
      final DateTime dt =
          DateTime.tryParse(h.updatedAt) ??
          DateTime.tryParse(h.createdAt) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return ChestItem.honoo(h, dt);
    }).toList();

    final hinooItems = _hinoo
        .map<ChestItem>((r) => ChestItem.hinoo(r))
        .toList();

    final items = [...honooItems, ...hinooItems];
    final organization = ChestOrganizer.organize<ChestItem>(
      items: items,
      createdAtOf: (item) => item.createdAt,
      stableIdOf: _stableIdOf,
      latestReplyOf: (item) => item.when(
        honoo: (h) => _honooLatestReplies[h.conversationId ?? h.dbId ?? ''],
        hinoo: (row) =>
            _hinooLatestReplies[row.conversationId ??
                row.draft.conversationId ??
                row.id],
      ),
      conversationIdOf: _convIdOfItem,
    );
    _itemsNormal = organization.items;

    var desiredIndex = previousIdentity == null
        ? -1
        : _itemsNormal.indexWhere(
            (item) => _slideIdentity(item) == previousIdentity,
          );
    if (_mode == ChestMode.normal && !_didApplyInitialFocus) {
      if (widget.focusConversationId != null) {
        final idx = _itemsNormal.indexWhere((it) {
          final String? cid = it.when(
            honoo: (h) => h.conversationId,
            hinoo: (row) => row.conversationId ?? row.draft.conversationId,
          );
          return cid == widget.focusConversationId;
        });
        if (idx >= 0) {
          desiredIndex = idx;
        } else {
          desiredIndex = 0;
        }
      } else {
        // L'ordinamento è dal più recente: durante il caricamento progressivo
        // non conservare una selezione provvisoria che potrebbe diventare
        // meno recente quando arrivano anche gli altri tipi di contenuto.
        desiredIndex = 0;
      }
      if (_initialLoadCompleted && _itemsNormal.isNotEmpty) {
        _didApplyInitialFocus = true;
      }
    }
    if (_mode == ChestMode.normal) {
      if (_itemsNormal.isEmpty) {
        desiredIndex = 0;
      } else if (desiredIndex < 0) {
        desiredIndex = _currentIndex.clamp(0, _itemsNormal.length - 1);
      }
      final indexChanged = desiredIndex != _currentIndex;
      _currentIndex = desiredIndex;
      if (indexChanged) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _itemsNormal.isEmpty) return;
          _carouselController.jumpToPage(_currentIndex);
        });
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _prefetchChestFrom(_currentIndex);
    });
  }

  List<String> _sortedActivitySignature(
    String prefix,
    Map<String, DateTime> activity,
  ) {
    final values = activity.entries
        .map((entry) => '$prefix:${entry.key}:${entry.value.toIso8601String()}')
        .toList();
    values.sort();
    return values;
  }

  List<String> _sortedReplySignature() {
    final values = _hinooRepliesByRoot.entries
        .map((entry) => '${entry.key}:${entry.value.length}')
        .toList();
    values.sort();
    return values;
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
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: _isMutating ? 0.55 : 1,
      child: IgnorePointer(
        ignoring: _isMutating,
        child: ChestFooter(
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
        ),
      ),
    );
  }

  Future<void> _sendHonooToMoon(Honoo honoo) async {
    if (_isMutating) return;
    setState(() => _isMutating = true);
    try {
      final result = await HonooController().sendToMoon(honoo);
      if (!mounted) return;
      setState(_rebuildItems);
      showHonooToast(
        context,
        message: result == DuplicationResult.inserted
            ? "L'honoo è anche sulla Luna."
            : "L'honoo era già presente sulla Luna.",
      );
    } catch (error) {
      if (!mounted) return;
      showHonooToast(context, message: 'Errore: $error');
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  Future<void> _deleteHonoo(Honoo honoo) async {
    final confirmed = await showHonooDeleteDialog(
      context,
      target: HonooDeletionTarget.honoo,
    );
    if (!mounted || confirmed != true) return;
    final String? id = honoo.dbId;
    if (id == null || id.isEmpty) {
      showHonooToast(context, message: 'Impossibile cancellare: id mancante.');
      return;
    }
    setState(() => _isMutating = true);
    try {
      await ctrl.deleteHonooById(id);
      if (!mounted) return;
      showHonooToast(context, message: 'honoo eliminato.');
    } catch (error) {
      if (!mounted) return;
      showHonooToast(
        context,
        message: 'Errore durante l\'eliminazione: $error',
      );
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  Future<void> _sendHinooToMoon(ChestHinooItem hinoo) async {
    if (_isMutating) return;
    setState(() => _isMutating = true);
    try {
      final result = await _hinooController.sendToMoon(hinoo.draft);
      if (!mounted) return;
      _chestController.markHinooOnMoon(hinoo.id);
      final text = result == HinooMoonResult.published
          ? "L'hinoo è anche sulla Luna."
          : "L'hinoo era già presente sulla Luna.";
      showHonooToast(context, message: text);
    } catch (error) {
      if (!mounted) return;
      showHonooToast(context, message: 'Errore: $error');
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  Future<void> _sendConversationEntryToMoon(ConversationEntry entry) async {
    if (_isMutating) return;
    if (entry.kind == ConversationEntryKind.deleted) return;
    setState(() => _isMutating = true);
    try {
      if (entry.kind == ConversationEntryKind.honoo) {
        final result = await HonooController().sendToMoon(entry.honoo!);
        if (!mounted) return;
        showHonooToast(
          context,
          message: result == DuplicationResult.inserted
              ? "L'honoo è anche sulla Luna."
              : "L'honoo era già presente sulla Luna.",
        );
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
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  Future<void> _deleteHinoo(ChestHinooItem current) async {
    final bool? confirmed = await showHonooDeleteDialog(
      context,
      target: HonooDeletionTarget.hinoo,
    );
    if (confirmed != true) return;

    if (_isMutating) return;
    setState(() => _isMutating = true);
    try {
      await _chestRepository.deleteHinoo(current.id);

      if (!mounted) return;
      _chestController.removeHinoo(current.id);
      showHonooToast(context, message: 'hinoo eliminato.');
    } catch (e) {
      if (!mounted) return;
      showHonooToast(context, message: 'Errore durante l\'eliminazione: $e');
    } finally {
      if (mounted) setState(() => _isMutating = false);
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
            initialHintText: 'Scrivi la tua risposta',
            initialImageHint: 'Aggiungi un’immagine (opzionale)',
            returnToPreviousOnAnswer: true,
          ),
        ),
      );
      _refreshConversationInPlace(result);
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
            targetContentName: 'honoo',
            forcedType: HinooType.answer,
            recipientTag: link.recipientId,
            replyTo: link.replyTo,
            conversationId: link.conversationId,
            returnToPreviousOnAnswer: true,
          ),
        ),
      );
      _refreshConversationInPlace(result);
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
            targetContentName: 'hinoo',
            originalHonoo:
                Honoo(
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
            initialHintText: 'Scrivi la tua risposta',
            initialImageHint: 'Aggiungi un’immagine (opzionale)',
            returnToPreviousOnAnswer: true,
          ),
        ),
      );
      _refreshConversationInPlace(result);
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
            targetContentName: 'hinoo',
            forcedType: HinooType.answer,
            recipientTag: link.recipientId,
            replyTo: link.replyTo,
            conversationId: link.conversationId,
            returnToPreviousOnAnswer: true,
          ),
        ),
      );
      _refreshConversationInPlace(result);
    }
  }

  void _refreshConversationInPlace(Object? result) {
    if (!mounted) return;
    final navigation = result is ReplyNavigationResult ? result : null;
    final conversationId =
        navigation?.conversationId ?? (result is String ? result : null);
    if (conversationId == null || conversationId.isEmpty) return;
    setState(() {
      _pendingRevealEntryId = navigation?.replyId;
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
                      horizontal: 16,
                      vertical: 14,
                    ),
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
                      horizontal: 16,
                      vertical: 14,
                    ),
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
    ChestItem item,
    GlobalKey repaintKey,
  ) async {
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
      showHonooToast(
        context,
        message: 'Scrivi almeno 1 carattere prima di scaricare',
      );
      return;
    }

    try {
      final contentName = item.when(
        honoo: (_) => 'honoo',
        hinoo: (_) => 'hinoo',
      );
      final result = await _downloadCaptureService.captureAndSave(
        repaintKey: repaintKey,
        baseName: contentName,
        message: 'creato con honoo',
      );
      if (!mounted) return;
      if (result.savedToGallery) {
        await showDownloadSaveResult(
          context: context,
          contentName: contentName,
          openSavedImage: _downloadCaptureService.openSavedImage,
          result: result,
        );
      } else {
        showHonooToast(
          context,
          message: result.message.isNotEmpty
              ? result.message
              : 'Download avviato.',
        );
      }
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
      revealEntryId: _pendingRevealEntryId,
      onSelectConversationEntry: _selectConversationEntry,
      onDownload: () => _handleDownloadForItem(item, repaintKey),
      conversationRefreshToken: _conversationRefreshToken,
    );
  }

  Widget _buildLoadError({required bool compact}) {
    return Material(
      color: Colors.black.withValues(alpha: compact ? 0.72 : 0),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              compact
                  ? 'Scrigno non aggiornato: mostro gli ultimi dati disponibili.'
                  : 'Non riesco a caricare lo Scrigno.',
              textAlign: TextAlign.center,
              style: GoogleFonts.libreFranklin(
                color: HonooColor.onBackground,
                fontSize: compact ? 13 : 17,
              ),
            ),
            TextButton.icon(
              onPressed: () => unawaited(_loadAll()),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Riprova',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
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
          bodyBuilder: (ctx, viewW, availableH, layoutMode) {
            final HonooBuilderMetrics honooMetrics =
                ResponsiveLayout.honooBuilderMetrics(
                  availableHeight: availableH,
                  maxWidth: viewW,
                  mode: layoutMode,
                );
            final items = _itemsNormal;
            final loadError = _loadError;
            if ((ctrl.isLoading.value || _isHinooLoading) && items.isEmpty) {
              return const Center(child: LoadingSpinner(color: Colors.white));
            }
            if (items.isEmpty) {
              if (loadError != null) {
                return Center(child: _buildLoadError(compact: false));
              }
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
            const horizPhysics = PageScrollPhysics(
              parent: ClampingScrollPhysics(),
            );
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
                  setState(() {
                    _currentIndex = i;
                    _selectedConvEntry = null;
                  });
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
            final visibleSlider = loadError == null
                ? slider
                : Stack(
                    children: [
                      Positioned.fill(child: slider),
                      Positioned(
                        top: 8,
                        left: 16,
                        right: 16,
                        child: Center(child: _buildLoadError(compact: true)),
                      ),
                    ],
                  );
            // Il reveal della conversazione viene gestito da
            // UnifiedThreadView usando i messaggi reali del thread. Qui ogni
            // conversazione occupa ormai una sola slide del carosello.
            final bool isDesktop =
                layoutMode == ResponsiveLayoutMode.desktop ||
                layoutMode == ResponsiveLayoutMode.wideDesktop ||
                layoutMode == ResponsiveLayoutMode.largeDesktop;
            if (!isDesktop || items.length <= 1) {
              return visibleSlider;
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
              child: visibleSlider,
            );
          },
          footerBuilder:
              (
                ctx,
                mode,
                footerIconSize,
                footerGap,
                footerTopSpacing,
                footerBottomSpacing,
              ) {
                final items = _itemsNormal;
                final ChestItem? current = items.isEmpty
                    ? null
                    : items[_currentIndex];
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
enum ChestMode { normal, conversation }
