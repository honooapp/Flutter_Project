import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:flutter/material.dart';
import 'package:honoo/Entities/hinoo.dart';
import 'package:honoo/Entities/honoo.dart';
import 'package:honoo/Services/hinoo_service.dart';
import 'package:honoo/Services/supabase_provider.dart';
import 'package:honoo/UI/hinoo_viewer.dart';
import 'package:honoo/UI/honoo_card.dart';
import 'package:honoo/Widgets/loading_spinner.dart';

class UnifiedThreadView extends StatefulWidget {
  const UnifiedThreadView({
    super.key,
    required this.conversationId,
    required this.maxWidth,
    required this.maxHeight,
  });

  final String conversationId;
  final double maxWidth;
  final double maxHeight;

  @override
  State<UnifiedThreadView> createState() => _UnifiedThreadViewState();
}

class _UnifiedThreadViewState extends State<UnifiedThreadView> {
  bool _loading = true;
  List<_Entry> _entries = const [];

  @override
  void initState() {
    super.initState();
    _load();
    _subscribe();
  }

  void _subscribe() {
    final client = SupabaseProvider.client;
    client
        .channel('conv-${widget.conversationId}')
        .on(RealtimeListenTypes.postgresChanges,
            ChannelFilter(event: '*', schema: 'public', table: 'honoo'),
            (_) => _load())
        .on(RealtimeListenTypes.postgresChanges,
            ChannelFilter(event: '*', schema: 'public', table: 'hinoo'),
            (_) => _load())
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
          .select('id,pages,type,recipient_tag,reply_to,created_at,user_id,conversation_id')
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
        entries.add(_Entry.hinoo(draft));
      }
      entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: LoadingSpinner());
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final e = _entries[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: e.when(
            honoo: (h) => SizedBox(
              width: widget.maxWidth,
              height: (widget.maxHeight * 0.66).clamp(240, widget.maxHeight),
              child: HonooCard(honoo: h),
            ),
            hinoo: (d) => SizedBox(
              width: widget.maxWidth,
              height: widget.maxHeight,
              child: HinooViewer(draft: d, maxHeight: widget.maxHeight, maxWidth: widget.maxWidth),
            ),
          ),
        );
      },
    );
  }
}

class _Entry {
  final Honoo? honoo;
  final HinooDraft? hinoo;
  final DateTime createdAt;

  _Entry._(this.honoo, this.hinoo, this.createdAt);
  factory _Entry.honoo(Honoo h) => _Entry._(h, null, DateTime.tryParse(h.createdAt) ?? DateTime.now());
  factory _Entry.hinoo(HinooDraft d) => _Entry._(null, d, DateTime.now());

  T when<T>({required T Function(Honoo) honoo, required T Function(HinooDraft) hinoo}) {
    if (this.honoo != null) return honoo(this.honoo!);
    return hinoo(this.hinoo!);
  }
}

