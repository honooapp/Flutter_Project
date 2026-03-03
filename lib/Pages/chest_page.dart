import 'dart:async';
import 'dart:ui' as ui;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:honoo/env/env.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:honoo/Services/supabase_provider.dart';
import 'package:honoo/UI/HinooBuilder/services/download_saver.dart';

import '../Controller/honoo_controller.dart';
import '../Controller/hinoo_controller.dart';
import '../Entities/honoo.dart';
import '../Entities/hinoo.dart';

import '../UI/honoo_thread_view.dart';
import '../UI/hinoo_viewer.dart';
import '../UI/hinoo_thread_view.dart';
import '../UI/hinoo_typography.dart';
import '../UI/unified_thread_view.dart';

import '../Utility/honoo_colors.dart';
import '../Utility/responsive_layout.dart';

import '../Widgets/honoo_dialogs.dart';
import '../Widgets/loading_spinner.dart';
import '../Widgets/honoo_app_title.dart';
import '../Widgets/luna_fissa.dart';
import '../Widgets/responsive_footer_bar.dart';
import '../Widgets/desktop_carousel_arrows.dart';
import '../UI/thread_layout_scaffold.dart';

import 'reply_honoo_page.dart';
import 'new_hinoo_page.dart';
import 'home_page.dart';
import 'placeholder_page.dart';

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
  bool _isBouncing = false;
  String? _bouncedConvId;
  // removed unused selected conversation index (not needed for rendering)

  static const String _scrignoInfoPrefKey = 'scrigno_info_seen_v1';
  static const String scrignoText =
      "Questo è il tuo Scrigno.\n\n"
      "Qui sono custoditi\n"
      "gli honoo e gli hinoo\n"
      "che hai scritto,\n\n"
      "quelli che hai salvato dalla Luna,\n\n"
      "e quelli che hai ricevuto.\n\n"
      "Blu\n"
      "sono i tuoi.\n\n"
      "Bianco\n"
      "quelli della Luna.\n\n"
      "Rosso\n"
      "quelli che ti sono stati inviati.\n\n"
      "Scorri verso destra\n"
      "per rivedere ciò che hai scritto\n"
      "e ciò che hai salvato.\n\n"
      "Scorri dall’alto verso il basso\n"
      "per seguire\n"
      "le conversazioni.\n\n"
      "In alto\n"
      "l’honoo della Luna.\n\n"
      "Sotto\n"
      "la tua risposta.\n\n"
      "E, sotto ancora,\n"
      "se arriva,\n"
      "la risposta\n"
      "alla tua risposta.\n";
  final HonooController ctrl = HonooController();
  final HinooController _hinooController = HinooController();

  int _currentIndex = 0;
  // Data lists for normal vs conversation mode
  List<_ChestItem> _itemsNormal = const [];
  List<_ChestItem> _itemsConversation = const [];
  List<_HinooRow> _hinoo = const [];
  final Map<String, DateTime> _honooLatestReplies = {};
  final Map<String, DateTime> _hinooLatestReplies = {};
  final Map<String, List<HinooThreadEntry>> _hinooRepliesByRoot = {};
  ConversationEntry? _selectedConvEntry;
  bool _isHinooLoading = true;
  bool _isRefreshingReplies = false;
  Timer? _replyRefreshTimer;
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
    _loadAll();
    _maybeShowScrignoHint();
    _replyRefreshTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _refreshReplies(),
    );
  }

  @override
  void dispose() {
    _replyRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _maybeShowScrignoHint() async {
    // Skip hint in CI/test environments to avoid flakiness in widget tests
    final bool inCi = const bool.fromEnvironment('CI', defaultValue: false) ||
        readEnv('CI') == 'true' ||
        readEnv('FLUTTER_TEST') == 'true';
    if (inCi) return;
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_scrignoInfoPrefKey) ?? false;
    if (seen) return;
    await prefs.setBool(_scrignoInfoPrefKey, true);
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
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double maxWidth =
                (constraints.maxWidth * 0.8).clamp(0.0, constraints.maxWidth);
            final double maxHeight =
                (constraints.maxHeight * 0.8).clamp(0.0, constraints.maxHeight);
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  maxHeight: maxHeight,
                ),
                child: Stack(
                  children: [
                    ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: maxWidth,
                          height: maxHeight,
                          padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                          decoration: BoxDecoration(
                            color: HonooColor.wave1.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Text(
                              scrignoText,
                              style: HonooDialogStyles.body(
                                color: HonooColor.onBackground,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: HonooColor.onBackground,
                        ),
                        iconSize: 40,
                        tooltip: 'Chiudi',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _loadAll() async {
    try {
      await ctrl.loadChest();
    } catch (_) {}
    await _loadHinoo(rebuild: false);
    await _loadReplyData();
    if (!mounted) return;
    setState(_rebuildItems);
  }

  Future<void> _refreshReplies() async {
    if (_isRefreshingReplies) return;
    _isRefreshingReplies = true;
    try {
      await _loadReplyData();
      if (!mounted) return;
      setState(_rebuildItems);
    } finally {
      _isRefreshingReplies = false;
    }
  }

  Future<void> _loadHinoo({bool rebuild = true}) async {
    final uid = SupabaseProvider.client.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) setState(() => _isHinooLoading = false);
      return;
    }

    if (mounted) setState(() => _isHinooLoading = true);

    try {
      final rows = await _fetchHinooRows(uid);

      final list = <_HinooRow>[];
      for (final r in rows) {
        final pages = r['pages'];
        if (pages is! List) continue;

        final draft = HinooDraft(
          pages: pages
              .whereType<Map<String, dynamic>>()
              .map((e) => HinooSlide.fromJson(e))
              .toList(),
          type: _hinooTypeFrom(r['type'] as String?),
          recipientTag: r['recipient_tag'] as String?,
          replyTo: r['reply_to'] as String?,
          conversationId: r['conversation_id']?.toString(),
          isFromMoonSaved: (r['is_from_moon_saved'] as bool?) ?? false,
        );

        final created = DateTime.tryParse((r['created_at'] ?? '').toString()) ??
            DateTime.now();

        final String? id = r['id']?.toString();
        if (id != null && id.isNotEmpty) {
          final bool isFromMoonSaved =
              (r['is_from_moon_saved'] as bool?) ?? false;
          list.add(
            _HinooRow(
              id: id,
              draft: draft,
              createdAt: created,
              isFromMoonSaved: isFromMoonSaved,
              ownerId: r['user_id']?.toString(),
              conversationId: r['conversation_id']?.toString(),
            ),
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _hinoo = list;
        _isHinooLoading = false;
        if (rebuild) _rebuildItems();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isHinooLoading = false);
    }
  }

  Future<List<dynamic>> _fetchHinooRows(String uid) async {
    final client = SupabaseProvider.client;
    try {
      final rows = await client
          .from('hinoo')
          .select('id,pages,type,reply_to,recipient_tag,created_at,is_from_moon_saved,user_id,conversation_id')
          .eq('user_id', uid)
          .in_('type', ['personal', 'moon'])
          .order('created_at', ascending: false);
      if (rows is List) return rows;
      if (rows is Map) return [rows];
      return const [];
    } on PostgrestException catch (e) {
      final combined = '${e.message} ${e.details ?? ''} ${e.hint ?? ''}';
      if (!combined.contains('is_from_moon_saved')) {
        rethrow;
      }
      final rows = await client
          .from('hinoo')
          .select('id,pages,type,reply_to,recipient_tag,created_at,user_id,conversation_id')
          .eq('user_id', uid)
          .in_('type', ['personal', 'moon'])
          .order('created_at', ascending: false);
      if (rows is List) return rows;
      if (rows is Map) return [rows];
      return const [];
    }
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
    final honooItems = ctrl.personal.map<_ChestItem>((h) {
      // Use updated_at when available to satisfy ordering by last activity/edit
      final DateTime dt = DateTime.tryParse(h.updatedAt) ??
          DateTime.tryParse(h.createdAt) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return _ChestItem.honoo(h, dt);
    }).toList();

    final hinooItems =
        _hinoo.map<_ChestItem>((r) => _ChestItem.hinoo(r)).toList();

    final items = [...honooItems, ...hinooItems];
    final List<_ChestItem> conversationItems = [];
    final List<_ChestItem> otherItems = [];
    for (final item in items) {
      final DateTime? replyAt = item.when(
        honoo: (h) => _honooLatestReplies[h.dbId ?? ''],
        hinoo: (row) => _hinooLatestReplies[row.id],
      );
      if (replyAt != null) {
        conversationItems.add(item);
      } else {
        otherItems.add(item);
      }
    }

    conversationItems.sort((a, b) {
      final DateTime? aReply = a.when(
        honoo: (h) => _honooLatestReplies[h.dbId ?? ''],
        hinoo: (row) => _hinooLatestReplies[row.id],
      );
      final DateTime? bReply = b.when(
        honoo: (h) => _honooLatestReplies[h.dbId ?? ''],
        hinoo: (row) => _hinooLatestReplies[row.id],
      );
      if (aReply == null && bReply == null) return 0;
      if (aReply == null) return 1;
      if (bReply == null) return -1;
      return bReply.compareTo(aReply);
    });

    otherItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _itemsNormal = [...conversationItems, ...otherItems];

    // Post-processing: group conversation entries contiguously, newest-first within each group.
    // Preserve the position of the most recent element of each group according to current ordering.
    if (_itemsNormal.isNotEmpty) {
      final List<_ChestItem> items = List.of(_itemsNormal);
      final int n = items.length;
      final Set<int> consumed = <int>{};
      final List<_ChestItem> regrouped = [];

      String? convIdOf(_ChestItem it) => it.when(
            honoo: (h) => h.conversationId,
            hinoo: (row) => row.conversationId ?? row.draft.conversationId,
          );

      for (int i = 0; i < n; i++) {
        if (consumed.contains(i)) continue;
        final _ChestItem it = items[i];
        final String? cid = convIdOf(it);
        if (cid == null || cid.isEmpty) {
          regrouped.add(it);
          consumed.add(i);
          continue;
        }

        // Collect all members of this conversation that are not yet consumed
        final List<_ChestItem> group = [];
        final List<int> groupIdx = [];
        for (int j = i; j < n; j++) {
          if (consumed.contains(j)) continue;
          final _ChestItem cand = items[j];
          final String? ccid = convIdOf(cand);
          if (ccid == cid) {
            group.add(cand);
            groupIdx.add(j);
          }
        }

        if (group.length <= 1) {
          // Nothing to group
          regrouped.add(it);
          consumed.add(i);
          continue;
        }

        // Sort within group by createdAt DESC (newest first)
        group.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        regrouped.addAll(group);
        for (final gIdx in groupIdx) {
          consumed.add(gIdx);
        }
      }

      _itemsNormal = regrouped;
    }

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
      } else if (widget.focusReplies && conversationItems.isNotEmpty) {
        _currentIndex = 0;
      }
    } else if (_mode == ChestMode.normal &&
        widget.focusReplies &&
        conversationItems.isNotEmpty) {
      _currentIndex = 0;
    } else if (_mode == ChestMode.normal &&
        _currentIndex >= _itemsNormal.length) {
      _currentIndex = _itemsNormal.isEmpty ? 0 : _itemsNormal.length - 1;
    }
  }

  Future<void> _loadConversation(String conversationId) async {
    // Fetch honoo and hinoo rows for a conversation and merge into unified list
    final client = SupabaseProvider.client;
    try {
      // HONOO in conversation
      final honooRows = await client
          .from('honoo')
          .select(
              'id,text,image_url,destination,reply_to,recipient_tag,created_at,updated_at,user_id,conversation_id')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      final List<_ChestItem> merged = [];
      if (honooRows is List) {
        for (final r in honooRows.whereType<Map<String, dynamic>>()) {
          try {
            final h = Honoo.fromMap(r);
            final dt = DateTime.tryParse(h.createdAt) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            merged.add(_ChestItem.honoo(h, dt));
          } catch (_) {}
        }
      }

      // HINOO in conversation (fallback if is_from_moon_saved not available)
      Future<List<dynamic>> fetchConvHinoo() async {
        try {
          final rows = await client
              .from('hinoo')
              .select(
                  'id,pages,type,recipient_tag,reply_to,created_at,user_id,conversation_id,is_from_moon_saved')
              .eq('conversation_id', conversationId)
              .order('created_at', ascending: true);
          if (rows is List) return rows;
          if (rows is Map) return [rows];
          return const [];
        } on PostgrestException catch (e) {
          final combined = '${e.message} ${e.details ?? ''} ${e.hint ?? ''}';
          if (!combined.contains('is_from_moon_saved')) rethrow;
          final rows = await client
              .from('hinoo')
              .select(
                  'id,pages,type,recipient_tag,reply_to,created_at,user_id,conversation_id')
              .eq('conversation_id', conversationId)
              .order('created_at', ascending: true);
          if (rows is List) return rows;
          if (rows is Map) return [rows];
          return const [];
        }
      }

      final hinooRows = await fetchConvHinoo();
      for (final r in hinooRows.whereType<Map<String, dynamic>>()) {
        final pages = r['pages'];
        if (pages is! List) continue;
        final draft = HinooDraft(
          pages: pages
              .whereType<Map<String, dynamic>>()
              .map((e) => HinooSlide.fromJson(e))
              .toList(),
          type: _hinooTypeFrom(r['type'] as String?),
          recipientTag: r['recipient_tag'] as String?,
          replyTo: r['reply_to'] as String?,
          conversationId: r['conversation_id']?.toString(),
          isFromMoonSaved: (r['is_from_moon_saved'] as bool?) ?? false,
        );
        final created = DateTime.tryParse((r['created_at'] ?? '').toString()) ??
            DateTime.now();
        final String? id = r['id']?.toString();
        if (id != null && id.isNotEmpty) {
          merged.add(
            _ChestItem.hinoo(
              _HinooRow(
                id: id,
                draft: draft,
                createdAt: created,
                isFromMoonSaved: (r['is_from_moon_saved'] as bool?) ?? false,
                ownerId: r['user_id']?.toString(),
                conversationId: r['conversation_id']?.toString(),
              ),
            ),
          );
        }
      }

      // Sort by createdAt DESC so newest is index 0
      merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!mounted) return;
      if (merged.isEmpty) {
        setState(() {
          _itemsConversation = const [];
        });
        _exitConversation();
        return;
      }
      // If conversation has only one element, avoid locking the carousel into conversation mode.
      if (merged.length <= 1) {
        setState(() {
          _itemsConversation = merged;
        });
        _exitConversation();
        return;
      }
      setState(() {
        _itemsConversation = merged;
        // Always start from newest item (index 0)
        _currentIndex = 0;
      });
      // Ensure PageView (Carousel) jumps to page 0 in conversation mode
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_mode == ChestMode.conversation) {
          try {
            _carouselController.jumpToPage(0);
          } catch (_) {}
          // Trigger bounce once when entering a conversation, if there is another entry to reveal
          if (_itemsConversation.length > 1 &&
              (_bouncedConvId != conversationId)) {
            _runConversationBounce();
            _bouncedConvId = conversationId;
          }
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _itemsConversation = const [];
      });
    }
  }

  String? _convIdOfItem(_ChestItem it) => it.when(
        honoo: (h) => h.conversationId,
        hinoo: (row) => row.conversationId ?? row.draft.conversationId,
      );

  PageController? _findPageController() {
    try {
      final dynamic cc = _carouselController;
      // Try direct pageController
      final dynamic pc1 = (cc as dynamic).pageController;
      if (pc1 is PageController) return pc1;
      // Try via state
      final dynamic state = (cc as dynamic).state;
      final dynamic pc2 = state?.pageController;
      if (pc2 is PageController) return pc2;
    } catch (_) {}
    return null;
  }

  Future<void> _runConversationBounce() async {
    if (!mounted || _isBouncing) return;
    final pc = _findPageController();
    if (pc == null || !pc.hasClients) return;
    final position = pc.position;
    // Ensure current item is part of a conversation with at least 2 elements
    final items = _mode == ChestMode.normal ? _itemsNormal : _itemsConversation;
    final int i = _currentIndex;
    if (i < 0 || i >= items.length) return;
    final String? cid = _convIdOfItem(items[i]);
    if (cid == null || cid.isEmpty) return;
    // Robust sibling check: any other item with same conv id and different identity
    bool hasSibling = false;
    for (int k = 0; k < items.length; k++) {
      if (k == i) continue;
      if (_convIdOfItem(items[k]) == cid) {
        hasSibling = true;
        break;
      }
    }
    if (!hasSibling) return;
    // Pick a visible sibling direction: prefer next, fallback to previous
    int dir = 0;
    if (i + 1 < items.length && _convIdOfItem(items[i + 1]) == cid) {
      dir = 1;
    } else if (i - 1 >= 0 && _convIdOfItem(items[i - 1]) == cid) {
      dir = -1;
    }
    if (dir == 0) return;

    final double extent = position.viewportDimension;
    if (extent <= 0) return;
    final double start = position.pixels;
    final double targetUnclamped = start + extent * 0.5 * dir;
    final double target = targetUnclamped
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    setState(() => _isBouncing = true);
    try {
      await position.animateTo(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
      if (!mounted) return;
      await position.animateTo(
        start,
        duration: const Duration(milliseconds: 400),
        curve: Curves.elasticOut,
      );
    } catch (_) {
      // ignore runtime animation errors
    } finally {
      if (mounted) {
        setState(() => _isBouncing = false);
      }
    }
  }

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

  Future<void> _loadReplyData() async {
    final uid = SupabaseProvider.client.auth.currentUser?.id;
    if (uid == null) return;
    final client = SupabaseProvider.client;
    try {
      _honooLatestReplies.clear();
      _hinooLatestReplies.clear();
      _hinooRepliesByRoot.clear();

      final honooRepliesToMe = await client
          .from('honoo')
          .select('reply_to,created_at')
          .eq('destination', 'reply')
          .eq('recipient_tag', uid);

      final honooRepliesFromMe = await client
          .from('honoo')
          .select('reply_to,created_at')
          .eq('destination', 'reply')
          .eq('user_id', uid);

      final honooReplies = <dynamic>[
        ...((honooRepliesToMe as List?) ?? const []),
        ...((honooRepliesFromMe as List?) ?? const []),
      ];
      // Deduplicate processing to avoid redundant map updates (no behavior change)
      final seenHonooKeys = <String>{};
      for (final row in honooReplies) {
        if (row is! Map) continue;
        final String rootId = row['reply_to']?.toString() ?? '';
        if (rootId.isEmpty) continue;
        final String createdRaw = (row['created_at'] ?? '').toString();
        final DateTime created =
            DateTime.tryParse(createdRaw) ?? DateTime.now();
        final String key = '$rootId|$createdRaw';
        if (!seenHonooKeys.add(key)) continue;
        final DateTime? existing = _honooLatestReplies[rootId];
        if (existing == null || created.isAfter(existing)) {
          _honooLatestReplies[rootId] = created;
        }
      }

      final List<String> rootHinooIds = _hinoo.map((row) => row.id).toList();
      if (rootHinooIds.isEmpty) return;

      final hinooRepliesToMe = await client
          .from('hinoo')
          .select('id,reply_to,pages,type,recipient_tag,created_at,user_id')
          .eq('type', 'answer')
          .eq('recipient_tag', uid)
          .in_('reply_to', rootHinooIds)
          .order('created_at', ascending: true);

      final hinooRepliesFromMe = await client
          .from('hinoo')
          .select('id,reply_to,pages,type,recipient_tag,created_at,user_id')
          .eq('type', 'answer')
          .eq('user_id', uid)
          .in_('reply_to', rootHinooIds)
          .order('created_at', ascending: true);

      final hinooReplies = <dynamic>[
        ...((hinooRepliesToMe as List?) ?? const []),
        ...((hinooRepliesFromMe as List?) ?? const []),
      ];
      final seenHinooIds = <String>{};

      for (final row in hinooReplies) {
        if (row is! Map) continue;
        final String id = row['id']?.toString() ?? '';
        if (id.isNotEmpty && !seenHinooIds.add(id)) continue;
        final String rootId = row['reply_to']?.toString() ?? '';
        if (rootId.isEmpty) continue;
        final pages = row['pages'];
        if (pages is! List) continue;
        final DateTime created = DateTime.tryParse(
                (row['created_at'] ?? '').toString()) ??
            DateTime.now();
        final draft = HinooDraft(
          pages: pages
              .whereType<Map<String, dynamic>>()
              .map(HinooSlide.fromJson)
              .toList(),
          type: HinooType.answer,
          recipientTag: row['recipient_tag'] as String?,
          replyTo: rootId,
        );
        _hinooRepliesByRoot
            .putIfAbsent(rootId, () => [])
            .add(HinooThreadEntry(
              draft: draft,
              authorId: row['user_id']?.toString(),
              isReply: true,
              createdAt: created,
            ));
        final DateTime? existing = _hinooLatestReplies[rootId];
        if (existing == null || created.isAfter(existing)) {
          _hinooLatestReplies[rootId] = created;
        }
      }
    } catch (_) {}
  }

  // --- helper menu
  bool _isPersonal(Honoo h) => h.type == HonooType.personal;
  bool _hasReplies(Honoo h) => h.hasReplies == true;
  bool _isFromMoonSaved(Honoo h) => h.isFromMoonSaved == true;
  bool _isHinooFromMoon(_HinooRow row) => row.isFromMoonSaved;
  HinooType _hinooTypeFrom(String? value) {
    if (value == 'moon' || value == 'public') return HinooType.moon;
    if (value == 'answer') return HinooType.answer;
    return HinooType.personal;
  }

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
          ResponsiveFooterAction(
            asset: "assets/icons/info.svg",
            semanticsLabel: 'Info',
            colorFilter: const ColorFilter.mode(
              HonooColor.onBackground,
              BlendMode.srcIn,
            ),
            size: iconSize,
            splashRadius: 25,
            tooltip: 'Info',
            onPressed: _showScrignoInfo,
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
      ResponsiveFooterAction(
        asset: "assets/icons/info.svg",
        semanticsLabel: 'Info',
        colorFilter: const ColorFilter.mode(
          HonooColor.onBackground,
          BlendMode.srcIn,
        ),
        size: iconSize,
        splashRadius: 25,
        tooltip: 'Info',
        onPressed: _showScrignoInfo,
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
              message: ok
                  ? "L'honoo è anche sulla Luna."
                  : "L'honoo era già presente sulla Luna.",
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
          onPressed: () => _showReplyChoiceForHonoo(current),
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

    // Conversazione unificata: azione di invio sulla Luna per entry selezionata
    final String? convId = current.conversationId;
    if (convId != null && convId.isNotEmpty && _selectedConvEntry != null) {
      final entry = _selectedConvEntry!;
      final String? myId = SupabaseProvider.client.auth.currentUser?.id;
      final bool isMine = entry.ownerId != null && myId != null && entry.ownerId == myId;
      final bool isPersonalEntry = entry.kind == ConversationEntryKind.honoo
          ? (entry.honoo!.type == HonooType.personal)
          : (entry.hinoo!.type == HinooType.personal);
      if (isMine && isPersonalEntry) {
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
                if (entry.kind == ConversationEntryKind.honoo) {
                  final ok = await HonooController().sendToMoon(entry.honoo!);
                  if (!mounted) return;
                  showHonooToast(context,
                      message: ok
                          ? "L'honoo è anche sulla Luna."
                          : "L'honoo era già presente sulla Luna.");
                } else {
                  final result = await _hinooController.sendToMoon(entry.hinoo!);
                  if (!mounted) return;
                  final text = result == HinooMoonResult.published
                      ? "L'hinoo è anche sulla Luna."
                      : "L'hinoo era già presente sulla Luna.";
                  showHonooToast(context, message: text);
                }
              } catch (e) {
                if (!mounted) return;
                showHonooToast(context, message: 'Errore: $e');
              }
            },
          ),
        );
      }
    }

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
      ResponsiveFooterAction(
        asset: "assets/icons/info.svg",
        semanticsLabel: 'Info',
        colorFilter: const ColorFilter.mode(
          HonooColor.onBackground,
          BlendMode.srcIn,
        ),
        size: iconSize,
        splashRadius: 25,
        tooltip: 'Info',
        onPressed: _showScrignoInfo,
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
                  ? "L'hinoo è anche sulla Luna."
                  : "L'hinoo era già presente sulla Luna.";
              showHonooToast(context, message: text);
            } catch (e) {
              if (!mounted) return;
              showHonooToast(context, message: 'Errore: $e');
            }
          },
        ),
      );
    } else if (isFromMoonSaved) {
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
          onPressed: () => _showReplyChoiceForHinoo(current),
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

  Future<void> _showReplyChoiceForHonoo(Honoo current) async {
    final _ReplyChoice? choice = await _showReplyChoice();
    if (choice == null || !mounted) return;
    if (choice == _ReplyChoice.honoo) {
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
    } else {
      final String? replyTo = current.dbId;
      if (replyTo == null || replyTo.isEmpty) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewHinooPage(
            forcedType: HinooType.answer,
            recipientTag: current.recipientTag,
            replyTo: replyTo,
            conversationId: replyTo,
          ),
        ),
      );
    }
  }

  Future<void> _showReplyChoiceForHinoo(_HinooRow current) async {
    final _ReplyChoice? choice = await _showReplyChoice();
    if (choice == null || !mounted) return;
    if (choice == _ReplyChoice.honoo) {
      final String replyTo = current.id;
      final String recipient = current.ownerId ?? current.draft.recipientTag ?? '';
      if (recipient.isEmpty) return;
      Navigator.push(
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
              replyTo,
              recipient,
            )..dbId = replyTo,
            initialHintText: 'Scrivi la tua risposta...',
            initialImageHint: 'Aggiungi un’immagine (opzionale)',
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewHinooPage(
            forcedType: HinooType.answer,
            recipientTag: current.draft.recipientTag,
            replyTo: current.id,
            conversationId: current.id,
          ),
        ),
      );
    }
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
  }

  Widget _wrapWithMoonFrame(Widget child, {required bool isMoonSaved}) {
    // Nessun contenitore bianco: mantieni full-size come gli altri
    return child;
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
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();

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
    ResponsiveLayoutMode layoutMode,
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

    final Size hinooSize = ResponsiveLayout.fitAspectRatio(
      targetMaxW,
      availableCenterH,
      HinooTypography.aspectRatio,
    );
    final double cardW = isHonoo ? honooMetrics.width : hinooSize.width;
    final double cardMaxH = isHonoo ? honooMetrics.height : hinooSize.height;

    final Widget content = item.when(
      honoo: (h) {
        final String? convId = h.conversationId;
        if (_mode == ChestMode.normal &&
            convId != null &&
            convId.isNotEmpty) {
          return UnifiedThreadView(
            conversationId: convId,
            maxWidth: targetMaxW,
            maxHeight: availableCenterH,
            onSelect: (e) => setState(() => _selectedConvEntry = e),
            highlightLatest: widget.highlightLatest &&
                (widget.focusConversationId != null &&
                    widget.focusConversationId == convId),
          );
        }
        // Se è una risposta, il thread deve essere costruito sul padre
        final Honoo effectiveRoot = (h.type == HonooType.answer &&
                (h.replyTo != null && h.replyTo!.isNotEmpty))
            ? h.copyWith(dbId: h.replyTo)
            : h;
        // Per i thread honoo usa tutta l'area centrale disponibile
        return SizedBox(
          width: targetMaxW,
          height: availableCenterH,
          child: HonooThreadView(
            root: effectiveRoot,
            onDownloadTap: () => _handleDownloadForItem(item, repaintKey),
          ),
        );
      },
      hinoo: (row) {
        final String? convId = row.conversationId ?? row.draft.conversationId;
        if (convId != null && convId.isNotEmpty && _mode == ChestMode.normal) {
          // Enter conversation mode structurally, then feed same builder
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (_activeConversationId == convId &&
                _mode == ChestMode.conversation) return;
            setState(() {
              _previousIndexBeforeConversation = _currentIndex;
              _mode = ChestMode.conversation;
              _activeConversationId = convId;
              _currentIndex = 0;
            });
            // Reset the controller to the first page (newest entry)
            try {
              _carouselController.jumpToPage(0);
            } catch (_) {}
            _loadConversation(convId);
          });
          return SizedBox(
            width: cardW,
            height: cardMaxH,
            child: const Center(
              child: LoadingSpinner(color: Colors.white),
            ),
          );
        }
        final replies = _hinooRepliesByRoot[row.id] ?? const [];
        if (replies.isEmpty) {
          return HinooViewer(
            draft: row.draft,
            maxHeight: cardMaxH,
            maxWidth: cardW,
            authorId: row.ownerId,
            onDownloadTap: () => _handleDownloadForItem(item, repaintKey),
          );
        }
        return HinooThreadView(
          root: row.draft,
          rootAuthorId: row.ownerId,
          replies: replies,
          maxHeight: cardMaxH,
          maxWidth: cardW,
          onDownloadTap: () => _handleDownloadForItem(item, repaintKey),
        );
      },
    );

    // Determina se stiamo mostrando un thread (honoo sempre thread; hinoo solo se ha risposte)
    final bool isThread = item.when(
      honoo: (_) => true,
      hinoo: (row) => (_hinooRepliesByRoot[row.id]?.isNotEmpty ?? false),
    );

    // Card: per i thread non applichiamo ClipRRect esterni né misure aggiuntive
    final Widget card = isThread
        ? RepaintBoundary(
            key: repaintKey,
            child: content,
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: cardW,
              child: RepaintBoundary(
                key: repaintKey,
                child: content,
              ),
            ),
          );

    // Apply borders ONLY around content box (non-thread)
    final String? currentUserId = SupabaseProvider.client.auth.currentUser?.id;
    bool showRedBorder = item.when(
      honoo: (h) => h.type == HonooType.answer && h.userId != currentUserId,
      hinoo: (row) =>
          row.draft.type == HinooType.answer && (row.ownerId ?? '') != currentUserId,
    );
    if (isThread) {
      showRedBorder = false; // never frame full-area thread views
    }
    bool showWhiteBorder = item.when(
      honoo: (h) => _isFromMoonSaved(h) && h.userId != currentUserId,
      hinoo: (row) => _isHinooFromMoon(row) && (row.ownerId ?? '') != currentUserId,
    );
    if (isThread) {
      showWhiteBorder = false; // never frame full-area thread views
    }

    final Widget styledCard = item.when(
      honoo: (h) {
        final Widget base = _wrapWithMoonFrame(
          card,
          isMoonSaved: _isFromMoonSaved(h),
        );
        if (showRedBorder) {
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red, width: 6),
            ),
            child: base,
          );
        } else if (showWhiteBorder) {
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 6),
            ),
            child: base,
          );
        }
        return base;
      },
      hinoo: (row) {
        final Widget base = _wrapWithMoonFrame(
          card,
          isMoonSaved: _isHinooFromMoon(row),
        );
        if (showRedBorder) {
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red, width: 6),
            ),
            child: base,
          );
        } else if (showWhiteBorder) {
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 6),
            ),
            child: base,
          );
        }
        return base;
      },
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: KeyedSubtree(
        key: ValueKey(identity),
        child: isThread
            ? SizedBox(
                width: targetMaxW,
                height: availableCenterH,
                child: styledCard,
              )
            : Center(
                child: SizedBox(
                  width: cardW,
                  height: cardMaxH,
                  child: styledCard,
                ),
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
            final items =
                _mode == ChestMode.normal ? _itemsNormal : _itemsConversation;
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
                onPageChanged: (i, _) => setState(() {
                  _currentIndex = i;
                }),
              ),
              itemBuilder: (context, index, realIdx) {
                return _buildChestItem(
                  items[index],
                  availableH,
                  viewW,
                  honooMetrics,
                  layoutMode,
                );
              },
            );
            // Trigger bounce in normal mode when highlighting latest or when selecting first of a conversation group
            if (_mode == ChestMode.normal && !_isBouncing) {
              final int i = _currentIndex;
              if (i >= 0 && i < items.length) {
                final String? cid = _convIdOfItem(items[i]);
                final bool hasConv = cid != null && cid.isNotEmpty;
                // Sibling validation (>= 2 elements in conversation)
                bool hasSibling = false;
                if (hasConv) {
                  for (int k = 0; k < items.length; k++) {
                    if (k == i) continue;
                    if (_convIdOfItem(items[k]) == cid) {
                      hasSibling = true;
                      break;
                    }
                  }
                }
                final bool isFirstOfGroup = hasConv &&
                    (i == 0 || _convIdOfItem(items[i - 1]) != cid);
                if (hasConv && hasSibling &&
                    (widget.highlightLatest || isFirstOfGroup) &&
                    (_bouncedConvId != cid)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    if (_bouncedConvId == cid) return;
                    _runConversationBounce();
                    _bouncedConvId = cid;
                  });
                }
              }
            }
            final bool isDesktop = layoutMode == ResponsiveLayoutMode.desktop ||
                layoutMode == ResponsiveLayoutMode.wideDesktop ||
                layoutMode == ResponsiveLayoutMode.largeDesktop;
            if (!isDesktop || items.length <= 1) {
              return AbsorbPointer(
                absorbing: _isBouncing,
                child: slider,
              );
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
              child: AbsorbPointer(
                absorbing: _isBouncing,
                child: slider,
              ),
            );
          },
          footerBuilder: (ctx, mode, footerIconSize, footerGap,
              footerTopSpacing, footerBottomSpacing) {
            final items =
                _mode == ChestMode.normal ? _itemsNormal : _itemsConversation;
            final _ChestItem? current =
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
  final bool isFromMoonSaved;
  final String? ownerId;
  final String? conversationId;

  const _HinooRow({
    required this.id,
    required this.draft,
    required this.createdAt,
    required this.isFromMoonSaved,
    required this.ownerId,
    this.conversationId,
  });
}

enum _ReplyChoice { honoo, hinoo }

// Public enum for Chest mode selection (local to this file usage)
enum ChestMode {
  normal,
  conversation,
}
