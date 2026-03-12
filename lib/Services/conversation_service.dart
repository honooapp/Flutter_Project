import 'package:honoo/Entities/hinoo.dart';
import 'package:honoo/Entities/honoo.dart';
import 'package:honoo/Entities/conversation_entry.dart';
import 'package:honoo/Services/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConversationService {
  static SupabaseClient get _client => SupabaseProvider.client;

  static Future<List<ConversationEntry>> fetchConversation(String conversationId) async {
    final honooRows = await _client
        .from('honoo')
        .select('id,text,image_url,destination,reply_to,recipient_tag,created_at,updated_at,user_id,conversation_id,is_from_moon_saved')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    final hinooRows = await _client
        .from('hinoo')
        .select('id,pages,type,recipient_tag,reply_to,created_at,user_id,conversation_id,is_from_moon_saved')
        .eq('conversation_id', conversationId)
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
        pages: pages.whereType<Map<String, dynamic>>().map(HinooSlide.fromJson).toList(),
        type: _fromDbType(r['type'] as String?),
        recipientTag: r['recipient_tag'] as String?,
        replyTo: r['reply_to'] as String?,
        conversationId: r['conversation_id']?.toString(),
        isFromMoonSaved: (r['is_from_moon_saved'] as bool?) ?? false,
      );
      final ownerId = r['user_id']?.toString();
      final bool isFromMoonSaved = (r['is_from_moon_saved'] as bool?) ?? false;
      entries.add(_Entry.hinoo(draft, ownerId: ownerId, isFromMoonSaved: isFromMoonSaved));
    }
    entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return entries
        .map((e) => e.when(
              honoo: (h) => ConversationEntry.honoo(h),
              hinoo: (d) => ConversationEntry.hinoo(d, ownerId: e.ownerId, isFromMoonSaved: e.isFromMoonSaved),
            ))
        .toList();
  }

  static RealtimeChannel subscribeConversation(String conversationId, void Function() onChange) {
    void refresh(dynamic _, [dynamic __]) => onChange();
    final chan = _client.channel('conv-$conversationId');
    chan
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
    return chan;
  }

  static HinooType _fromDbType(String? value) {
    if (value == 'moon' || value == 'public') return HinooType.moon;
    if (value == 'answer') return HinooType.answer;
    return HinooType.personal;
  }
}

class _Entry {
  final Honoo? honoo;
  final HinooDraft? hinoo;
  final DateTime createdAt;
  final String? ownerId;
  final bool isFromMoonSaved;

  _Entry._(this.honoo, this.hinoo, this.createdAt, {this.ownerId, this.isFromMoonSaved = false});
  factory _Entry.honoo(Honoo h) => _Entry._(h, null, DateTime.tryParse(h.createdAt) ?? DateTime.now(), ownerId: h.userId, isFromMoonSaved: h.isFromMoonSaved);
  factory _Entry.hinoo(HinooDraft d, {String? ownerId, bool isFromMoonSaved = false}) =>
      _Entry._(null, d, DateTime.now(), ownerId: ownerId, isFromMoonSaved: isFromMoonSaved);

  T when<T>({required T Function(Honoo) honoo, required T Function(HinooDraft) hinoo}) {
    if (this.honoo != null) return honoo(this.honoo!);
    return hinoo(this.hinoo!);
  }
}

