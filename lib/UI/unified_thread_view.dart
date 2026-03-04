import 'package:flutter/material.dart';
import 'package:honoo/Entities/hinoo.dart';
import 'package:honoo/Entities/honoo.dart';
import 'package:honoo/Services/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:honoo/UI/hinoo_viewer.dart';
import 'package:honoo/UI/honoo_card.dart';
import 'package:honoo/Widgets/loading_spinner.dart';
// rendering a lista con separatori; rimosso carousel verticale
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

class _UnifiedThreadViewState extends State<UnifiedThreadView> {
  bool _loading = true;
  List<_Entry> _entries = const [];
  RealtimeChannel? _chan;
  bool _didHighlight = false;

  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: LoadingSpinner());
    final double h = widget.maxHeight;
    return SizedBox(
      width: widget.maxWidth,
      height: h,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: _entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final e = _entries[index];
          final child = e.when(
            honoo: (h) => HonooCard(honoo: h),
            hinoo: (d) => HinooViewer(
              draft: d,
              maxHeight: widget.maxHeight,
              maxWidth: widget.maxWidth,
            ),
          );
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 250 + (index * 40)),
            curve: Curves.easeOut,
            builder: (context, value, childWidget) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 8),
                  child: childWidget,
                ),
              );
            },
            child: child,
          );
        },
      ),
    );
  }

  // Tile helpers non più utilizzati con il rendering a lista separata

  @override
  void dispose() {
    _chan?.unsubscribe();
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
