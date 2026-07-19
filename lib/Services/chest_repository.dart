import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_provider.dart';

/// Accesso dati dello Scrigno. Non contiene stato, mapping UI o ordinamento.
class ChestRepository {
  ChestRepository({SupabaseClient? client})
      : _client = client ?? SupabaseProvider.client;

  final SupabaseClient _client;

  Future<List<dynamic>> fetchHinooRows(String userId) async {
    try {
      final rows = await _client
          .from('hinoo')
          .select(
              'id,pages,type,reply_to,recipient_tag,created_at,is_from_moon_saved,user_id,conversation_id')
          .eq('user_id', userId)
          .in_('type', ['personal', 'answer'])
          .order('created_at', ascending: false);
      return _asList(rows);
    } on PostgrestException catch (error) {
      final combined =
          '${error.message} ${error.details ?? ''} ${error.hint ?? ''}';
      if (!combined.contains('is_from_moon_saved')) rethrow;

      final rows = await _client
          .from('hinoo')
          .select(
              'id,pages,type,reply_to,recipient_tag,created_at,user_id,conversation_id')
          .eq('user_id', userId)
          .in_('type', ['personal', 'answer'])
          .order('created_at', ascending: false);
      return _asList(rows);
    }
  }

  Future<List<dynamic>> fetchHonooReplyRows(String userId) async {
    final repliesToUser = await _client
        .from('honoo')
        .select('reply_to,created_at')
        .eq('destination', 'reply')
        .eq('recipient_tag', userId);
    final repliesFromUser = await _client
        .from('honoo')
        .select('reply_to,created_at')
        .eq('destination', 'reply')
        .eq('user_id', userId);
    return [..._asList(repliesToUser), ..._asList(repliesFromUser)];
  }

  Future<List<dynamic>> fetchHinooReplyRows(
    String userId,
    List<String> rootIds,
  ) async {
    if (rootIds.isEmpty) return const [];

    final repliesToUser = await _client
        .from('hinoo')
        .select('id,reply_to,pages,type,recipient_tag,created_at,user_id')
        .eq('type', 'answer')
        .eq('recipient_tag', userId)
        .in_('reply_to', rootIds)
        .order('created_at', ascending: true);
    final repliesFromUser = await _client
        .from('hinoo')
        .select('id,reply_to,pages,type,recipient_tag,created_at,user_id')
        .eq('type', 'answer')
        .eq('user_id', userId)
        .in_('reply_to', rootIds)
        .order('created_at', ascending: true);
    return [..._asList(repliesToUser), ..._asList(repliesFromUser)];
  }

  Future<void> deleteHinoo(String id) async {
    await _client.from('hinoo').delete().eq('id', id);
  }

  static List<dynamic> _asList(dynamic rows) {
    if (rows is List) return rows;
    if (rows is Map) return [rows];
    return const [];
  }
}
