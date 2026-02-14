import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:supabase_flutter/supabase_flutter.dart';
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

import '../Utility/honoo_colors.dart';
import '../Utility/responsive_layout.dart';

import '../Widgets/honoo_dialogs.dart';
import '../Widgets/loading_spinner.dart';
import '../Widgets/honoo_app_title.dart';
import '../Widgets/luna_fissa.dart';
import '../Widgets/responsive_footer_bar.dart';

import 'reply_honoo_page.dart';
import 'new_hinoo_page.dart';
import 'home_page.dart';
import 'placeholder_page.dart';

class ChestPage extends StatefulWidget {
  const ChestPage({super.key, this.focusReplies = false});

  final bool focusReplies;

  @override
  State<ChestPage> createState() => _ChestPageState();
}

class _ChestPageState extends State<ChestPage> {
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
  List<_ChestItem> _items = const [];
  List<_HinooRow> _hinoo = const [];
  final Map<String, DateTime> _honooLatestReplies = {};
  final Map<String, DateTime> _hinooLatestReplies = {};
  final Map<String, List<HinooThreadEntry>> _hinooRepliesByRoot = {};
  bool _isHinooLoading = true;
  bool _isRefreshingReplies = false;
  Timer? _replyRefreshTimer;

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
            return Stack(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: maxWidth,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: HonooColor.wave1.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SingleChildScrollView(
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
          .select('id,pages,type,reply_to,recipient_tag,created_at,is_from_moon_saved,user_id')
          .eq('user_id', uid)
          .in_('type', ['personal', 'moon'])
          .order('created_at', ascending: false);
      return rows as List<dynamic>;
    } on PostgrestException catch (e) {
      if (e.code != 'PGRST204' ||
          !e.message.contains('is_from_moon_saved')) {
        rethrow;
      }
      final rows = await client
          .from('hinoo')
          .select('id,pages,type,reply_to,recipient_tag,created_at,user_id')
          .eq('user_id', uid)
          .in_('type', ['personal', 'moon'])
          .order('created_at', ascending: false);
      return rows as List<dynamic>;
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

    _items = [...conversationItems, ...otherItems];

    if (widget.focusReplies && conversationItems.isNotEmpty) {
      _currentIndex = 0;
    } else if (_currentIndex >= _items.length) {
      _currentIndex = _items.isEmpty ? 0 : _items.length - 1;
    }
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

      for (final row in honooReplies) {
        if (row is! Map) continue;
        final String rootId = row['reply_to']?.toString() ?? '';
        if (rootId.isEmpty) continue;
        final DateTime created = DateTime.tryParse(
                (row['created_at'] ?? '').toString()) ??
            DateTime.now();
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
    if (!isMoonSaved) return child;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget _wrapHonooWithReplyBorder(Widget child, Honoo honoo) {
    if (honoo.type != HonooType.answer) return child;
    final String? uid = SupabaseProvider.client.auth.currentUser?.id;
    final bool isOwnReply = uid != null && honoo.userId == uid;
    final Color borderColor =
        isOwnReply ? HonooColor.wave2 : HonooColor.secondary;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: child,
    );
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
      honoo: (h) => SizedBox(
        width: honooMetrics.width,
        height: honooMetrics.height,
        child: HonooThreadView(
          root: h,
          onDownloadTap: () => _handleDownloadForItem(item, repaintKey),
        ),
      ),
      hinoo: (row) {
        final replies = _hinooRepliesByRoot[row.id] ?? const [];
        if (replies.isEmpty) {
          return HinooViewer(
            draft: row.draft,
            maxHeight: cardMaxH,
            maxWidth: cardW,
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

    // ✅ La "card reale" (bianca) è questa:
    final Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: cardW,
        child: RepaintBoundary(
          key: repaintKey,
          child: content,
        ),
      ),
    );

    final Widget styledCard = item.when(
      honoo: (h) => _wrapWithMoonFrame(
        _wrapHonooWithReplyBorder(card, h),
        isMoonSaved: _isFromMoonSaved(h),
      ),
      hinoo: (row) => _wrapWithMoonFrame(
        card,
        isMoonSaved: _isHinooFromMoon(row),
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
                styledCard,
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

                final ResponsiveLayoutMode layoutMode =
                    ResponsiveLayout.modeForWidth(constraints.maxWidth);
                final bool currentIsHinoo =
                    current != null && current.honoo == null;
                final double targetMaxW = currentIsHinoo
                    ? constraints.maxWidth
                    : layoutMode == ResponsiveLayoutMode.mobile
                        ? constraints.maxWidth
                        : ResponsiveLayout.contentMaxWidth(constraints.maxWidth);
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
                final double horizontalPadding = currentIsHinoo
                    ? 0
                    : layoutMode == ResponsiveLayoutMode.mobile ||
                            layoutMode == ResponsiveLayoutMode.tablet
                        ? 0
                        : 16;
                final double displayHeight = current?.honoo != null
                    ? honooMetrics.height
                    : availableCenterH;

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
                              0,
                            ),
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 90),
                              curve: Curves.easeOutCubic,
                              constraints:
                                  BoxConstraints(maxWidth: targetMaxW),
                              child: SizedBox(
                                height: displayHeight,
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
                                      padding: EdgeInsets.symmetric(
                                          horizontal: horizontalPadding),
                                      child: cs.CarouselSlider.builder(
                                        itemCount: _items.length,
                                        options: cs.CarouselOptions(
                                          height: displayHeight,
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
                                            padding: EdgeInsets.symmetric(
                                                horizontal: horizontalPadding),
                                            child: _buildChestItem(
                                              _items[index],
                                              availableCenterH,
                                              targetMaxW,
                                              honooMetrics,
                                              layoutMode,
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
  final bool isFromMoonSaved;
  final String? ownerId;

  const _HinooRow({
    required this.id,
    required this.draft,
    required this.createdAt,
    required this.isFromMoonSaved,
    required this.ownerId,
  });
}

enum _ReplyChoice { honoo, hinoo }
