import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:honoo/Entities/hinoo.dart';
import 'package:honoo/Entities/honoo.dart';
import 'package:honoo/Services/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:honoo/UI/hinoo_viewer.dart';
import 'package:honoo/UI/honoo_card.dart';
import 'package:honoo/Widgets/loading_spinner.dart';
import 'package:honoo/UI/HinooBuilder/services/download_saver.dart';
import 'package:honoo/Widgets/honoo_dialogs.dart';
// rendering a lista con separatori; rimosso carousel verticale

class UnifiedThreadView extends StatefulWidget {
  const UnifiedThreadView({
    super.key,
    required this.conversationId,
    required this.maxWidth,
    required this.maxHeight,
    this.onSelect,
    this.highlightLatest = false,
    this.isActive = false,
    this.onDownloadTap,
  });

  final String conversationId;
  final double maxWidth;
  final double maxHeight;
  final ValueChanged<ConversationEntry>? onSelect;
  final bool highlightLatest;
  final bool isActive;
  final VoidCallback? onDownloadTap;

  @override
  State<UnifiedThreadView> createState() => _UnifiedThreadViewState();
}

class _UnifiedThreadViewState extends State<UnifiedThreadView> with SingleTickerProviderStateMixin {
  bool _loading = true;
  List<_Entry> _entries = const [];
  RealtimeChannel? _chan;
  bool _didHighlight = false;
  bool _hasPlayedReveal = false;
  late AnimationController _controller;
  late Animation<double> _liftAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _liftAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: -1.0, end: 0.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _load();
    _subscribe();
  }

  void _subscribe() {
    final client = SupabaseProvider.client;
    void refresh(dynamic _, [dynamic __]) => _load();
    _chan = client.channel('conv-${widget.conversationId}');
    _chan!
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(event: '*', schema: 'public', table: 'honoo'),
          refresh,
        )
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(event: '*', schema: 'public', table: 'hinoo'),
          refresh,
        )
        .subscribe();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final c = SupabaseProvider.client;
      final honooRows = await c
          .from('honoo')
          .select('id,text,image_url,destination,reply_to,recipient_tag,created_at,updated_at,user_id,conversation_id')
          .eq('conversation_id', widget.conversationId)
          .order('created_at', ascending: true);
      final hinooRows = await c
          .from('hinoo')
          .select('id,pages,type,recipient_tag,reply_to,created_at,user_id,conversation_id,is_from_moon_saved')
          .eq('conversation_id', widget.conversationId)
          .order('created_at', ascending: true);

      final entries = <_Entry>[];
      for (final r in (honooRows as List)) {
        final h = Honoo.fromMap(Map<String, dynamic>.from(r));
        entries.add(_Entry.honoo(h));
      }
      for (final r in (hinooRows as List)) {
        final pages = r['pages'];
        if (pages is! List) continue;
        final draft = HinooDraft(
          pages: pages
              .whereType<Map<String, dynamic>>()
              .map(HinooSlide.fromJson)
              .toList(),
          type: HinooType.answer,
          recipientTag: r['recipient_tag'] as String?,
          replyTo: r['reply_to'] as String?,
          conversationId: r['conversation_id']?.toString(),
        );
        final ownerId = r['user_id']?.toString();
        final bool isFromMoonSaved = (r['is_from_moon_saved'] as bool?) ?? false;
        entries.add(_Entry.hinoo(draft, ownerId: ownerId, isFromMoonSaved: isFromMoonSaved));
      }
      entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
      if (widget.highlightLatest && !_didHighlight && _entries.isNotEmpty) {
        _didHighlight = true;
        widget.onSelect?.call(_toConversationEntry(_entries.last));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void didUpdateWidget(covariant UnifiedThreadView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_hasPlayedReveal && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Attiva reveal solo se la prima card (più recente) è una reply di altri (non moon-saved, non mia)
        if (_entries.isNotEmpty && _shouldReveal(_entries.last)) {
          _controller.forward();
          _hasPlayedReveal = true;
        }
      });
    }
  }

  bool _shouldReveal(_Entry e) {
    final String? myId = SupabaseProvider.client.auth.currentUser?.id;
    // Moon-saved: non rivelare
    final bool isMoon = e.isFromMoonSaved == true ||
        (e.honoo != null && (e.honoo!.isFromMoonSaved == true));
    if (isMoon) return false;

    // Creato da me: non rivelare
    if (e.ownerId != null && myId != null && e.ownerId == myId) return false;

    // Reply?
    final bool isReply = e.honoo != null
        ? (e.honoo!.type == HonooType.answer)
        : (e.hinoo != null && e.hinoo!.type == HinooType.answer);

    return isReply;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: LoadingSpinner());
    return SizedBox(
      width: widget.maxWidth,
      height: widget.maxHeight,
      child: PageView.builder(
        scrollDirection: Axis.vertical,
        physics: const BouncingScrollPhysics(),
        itemCount: _entries.length,
        itemBuilder: (context, index) {
          // Ordine inverso: ultimo (più recente) in cima
          final revIndex = _entries.length - 1 - index;
          final e = _entries[revIndex];
          final GlobalKey repaintKey = GlobalKey();
          Future<void> _download() => _downloadFromBoundary(
                repaintKey: repaintKey,
                baseName: e.honoo != null ? 'honoo' : 'hinoo',
              );
          final card = e.when(
            honoo: (h) => RepaintBoundary(
              key: repaintKey,
              child: HonooCard(honoo: h, onDownloadTap: _download),
            ),
            hinoo: (d) => RepaintBoundary(
              key: repaintKey,
              child: HinooViewer(
                draft: d,
                maxHeight: widget.maxHeight,
                maxWidth: widget.maxWidth,
                onDownloadTap: _download,
              ),
            ),
          );
          final Widget page = SizedBox.expand(child: card);
          if (index == 0 && _shouldReveal(e)) {
            final screenH = MediaQuery.of(context).size.height;
            return AnimatedBuilder(
              animation: _liftAnimation,
              builder: (context, childWidget) {
                final double offsetY = _liftAnimation.value * (screenH * 0.4);
                return Transform.translate(offset: Offset(0, offsetY), child: childWidget);
              },
              child: page,
            );
          }
          return page;
        },
      ),
    );
  }

  // Tile helpers non più utilizzati con il rendering a lista separata

  @override
  void dispose() {
    _chan?.unsubscribe();
    _controller.dispose();
    super.dispose();
  }

  ConversationEntry _toConversationEntry(_Entry e) {
    return e.when(
      honoo: (h) => ConversationEntry.honoo(h),
      hinoo: (d) => ConversationEntry.hinoo(d, ownerId: e.ownerId, isFromMoonSaved: e.isFromMoonSaved),
    );
  }
}

extension on _UnifiedThreadViewState {
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

      final saver = getDownloadSaver();
      final String filename = '${baseName}_${DateTime.now().millisecondsSinceEpoch}.png';
      await saver.save([DownloadImage(filename: filename, bytes: bytes)]);

      if (!mounted) return;
      showHonooToast(context, message: 'Download avviato.');
    } catch (e) {
      if (!mounted) return;
      showHonooToast(context, message: 'Errore download: $e');
    }
  }
}

class _Entry {
  final Honoo? honoo;
  final HinooDraft? hinoo;
  final DateTime createdAt;
  final String? ownerId;
  final bool isFromMoonSaved;

  _Entry._(this.honoo, this.hinoo, this.createdAt, {this.ownerId, this.isFromMoonSaved = false});
  factory _Entry.honoo(Honoo h) => _Entry._(h, null, DateTime.tryParse(h.createdAt) ?? DateTime.now(), ownerId: h.userId);
  factory _Entry.hinoo(HinooDraft d, {String? ownerId, bool isFromMoonSaved = false}) =>
      _Entry._(null, d, DateTime.now(), ownerId: ownerId, isFromMoonSaved: isFromMoonSaved);

  T when<T>({required T Function(Honoo) honoo, required T Function(HinooDraft) hinoo}) {
    if (this.honoo != null) return honoo(this.honoo!);
    return hinoo(this.hinoo!);
  }
}

enum ConversationEntryKind { honoo, hinoo }

class ConversationEntry {
  final ConversationEntryKind kind;
  final Honoo? honoo;
  final HinooDraft? hinoo;
  final String? ownerId;
  final bool isFromMoonSaved;

  ConversationEntry._(this.kind, {this.honoo, this.hinoo, this.ownerId, this.isFromMoonSaved = false});
  factory ConversationEntry.honoo(Honoo h) => ConversationEntry._(ConversationEntryKind.honoo, honoo: h, ownerId: h.userId, isFromMoonSaved: h.isFromMoonSaved);
  factory ConversationEntry.hinoo(HinooDraft d, {String? ownerId, bool isFromMoonSaved = false}) =>
      ConversationEntry._(ConversationEntryKind.hinoo, hinoo: d, ownerId: ownerId, isFromMoonSaved: isFromMoonSaved);
}
