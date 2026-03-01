import 'package:flutter/material.dart';
import 'package:honoo/Entities/hinoo.dart';
import 'package:honoo/Entities/honoo.dart';
import 'package:honoo/Services/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:honoo/UI/hinoo_viewer.dart';
import 'package:honoo/UI/honoo_card.dart';
import 'package:honoo/Widgets/loading_spinner.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:honoo/Utility/honoo_colors.dart';

class UnifiedThreadView extends StatefulWidget {
  const UnifiedThreadView({
    super.key,
    required this.conversationId,
    required this.maxWidth,
    required this.maxHeight,
    this.onSelect,
    this.highlightLatest = false,
  });

  final String conversationId;
  final double maxWidth;
  final double maxHeight;
  final ValueChanged<ConversationEntry>? onSelect;
  final bool highlightLatest;

  @override
  State<UnifiedThreadView> createState() => _UnifiedThreadViewState();
}

class _UnifiedThreadViewState extends State<UnifiedThreadView>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  List<_Entry> _entries = const [];
  RealtimeChannel? _chan;
  int _selected = 0;
  late final AnimationController _bounce;
  late final Animation<Offset> _offsetAnim;
  bool _didHighlight = false;
  bool _bouncingSelected = false;
  final cs.CarouselController _vController = cs.CarouselController();

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _offsetAnim = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_bounce);
    _bounce.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) setState(() => _bouncingSelected = false);
      }
    });
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
        _bounce.forward(from: 0);
        setState(() => _selected = _entries.length - 1);
        widget.onSelect?.call(_toConversationEntry(_entries.last));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: LoadingSpinner());
    final double h = widget.maxHeight;
    final bool useHint = widget.highlightLatest && !_didHighlight && _entries.isNotEmpty;
    final Widget list = SizedBox(
      width: widget.maxWidth,
      height: h,
      child: cs.CarouselSlider.builder(
        carouselController: _vController,
        itemCount: _entries.length,
        options: cs.CarouselOptions(
          height: h,
          scrollDirection: Axis.vertical,
          viewportFraction: 1.0,
          enableInfiniteScroll: false,
          padEnds: false,
          enlargeCenterPage: false,
          scrollPhysics: const BouncingScrollPhysics(),
          onPageChanged: (index, reason) {
            setState(() => _selected = index);
            widget.onSelect?.call(_toConversationEntry(_entries[index]));
            // Rimbalzo visivo sull'entry corrente dopo lo scorrimento
            if (reason != cs.CarouselPageChangedReason.controller) {
              setState(() => _bouncingSelected = true);
              _bounce.forward(from: 0);
            }
          },
        ),
        itemBuilder: (context, index, realIdx) {
          final e = _entries[index];
          final bool selected = index == _selected;
          final String? myId = SupabaseProvider.client.auth.currentUser?.id;
          final bool isOther = (e.ownerId != null && myId != null)
              ? (e.ownerId != myId)
              : false;
          final child = e.when(
            honoo: (h) => _buildHonooTile(h, selected, isOther: isOther),
            hinoo: (d) => _buildHinooTile(d, selected, isOther: isOther),
          );
          final bool shouldBounce =
              (useHint && index == _entries.length - 1) || (selected && _bouncingSelected);
          return shouldBounce
              ? SlideTransition(position: _offsetAnim, child: child)
              : child;
        },
      ),
    );
    return list;
  }

  Widget _buildHonooTile(Honoo h, bool selected, {required bool isOther}) {
    return SizedBox(
      width: widget.maxWidth,
      height: widget.maxHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
              color: isOther ? HonooColor.secondary : (selected ? Colors.white70 : Colors.transparent),
              width: isOther ? 6 : 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: HonooCard(honoo: h),
      ),
    );
  }

  Widget _buildHinooTile(HinooDraft d, bool selected, {required bool isOther}) {
    return SizedBox(
      width: widget.maxWidth,
      height: widget.maxHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
              color: isOther ? HonooColor.secondary : (selected ? Colors.white70 : Colors.transparent),
              width: isOther ? 6 : 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: HinooViewer(
            draft: d, maxHeight: widget.maxHeight, maxWidth: widget.maxWidth),
      ),
    );
  }

  @override
  void dispose() {
    _chan?.unsubscribe();
    _bounce.dispose();
    super.dispose();
  }

  ConversationEntry _toConversationEntry(_Entry e) {
    return e.when(
      honoo: (h) => ConversationEntry.honoo(h),
      hinoo: (d) => ConversationEntry.hinoo(d, ownerId: e.ownerId, isFromMoonSaved: e.isFromMoonSaved),
    );
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
