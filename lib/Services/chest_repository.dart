import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_provider.dart';
import 'reliability_policy.dart';

/// Accesso dati dello Scrigno. Non contiene stato, mapping UI o ordinamento.
class ChestRepository {
  ChestRepository({
    SupabaseClient? client,
    ReliabilityPolicy reliabilityPolicy = const ReliabilityPolicy(),
  }) : _client = client ?? SupabaseProvider.client,
       _reliability = reliabilityPolicy;

  final SupabaseClient _client;
  final ReliabilityPolicy _reliability;

  Future<Set<String>> fetchHinooMoonFingerprints(String userId) async {
    final rows = await _client
        .from('hinoo')
        .select('fingerprint')
        .eq('user_id', userId)
        .eq('type', 'moon');
    return _asList(rows)
        .map((row) => row is Map ? row['fingerprint']?.toString() : null)
        .whereType<String>()
        .where((fingerprint) => fingerprint.isNotEmpty)
        .toSet();
  }

  Future<List<dynamic>> fetchHinooRows(String userId) async {
    try {
      final rows = await _client
          .from('hinoo')
          .select(
            'id,pages,type,reply_to,recipient_tag,created_at,is_from_moon_saved,user_id,conversation_id',
          )
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
            'id,pages,type,reply_to,recipient_tag,created_at,user_id,conversation_id',
          )
          .eq('user_id', userId)
          .in_('type', ['personal', 'answer'])
          .order('created_at', ascending: false);
      return _asList(rows);
    }
  }

  Future<List<dynamic>> fetchHonooReplyRows(String userId) async {
    final repliesToUser = await _client
        .from('honoo')
        .select('conversation_id,reply_to,created_at,user_id')
        .eq('destination', 'reply')
        .eq('recipient_tag', userId);
    final repliesFromUser = await _client
        .from('honoo')
        .select('conversation_id,reply_to,created_at,user_id')
        .eq('destination', 'reply')
        .eq('user_id', userId);
    return [..._asList(repliesToUser), ..._asList(repliesFromUser)];
  }

  Future<List<dynamic>> fetchHinooReplyRows(
    String userId,
    List<String> _,
  ) async {
    final repliesToUser = await _client
        .from('hinoo')
        .select(
          'id,conversation_id,reply_to,pages,type,recipient_tag,created_at,user_id',
        )
        .eq('type', 'answer')
        .eq('recipient_tag', userId)
        .order('created_at', ascending: true);
    final repliesFromUser = await _client
        .from('hinoo')
        .select(
          'id,conversation_id,reply_to,pages,type,recipient_tag,created_at,user_id',
        )
        .eq('type', 'answer')
        .eq('user_id', userId)
        .order('created_at', ascending: true);
    return [..._asList(repliesToUser), ..._asList(repliesFromUser)];
  }

  Future<void> deleteHinoo(String id) async {
    await _reliability.write(
      () async => await _client.from('hinoo').delete().eq('id', id),
    );
  }

  static List<dynamic> _asList(dynamic rows) {
    if (rows is List) return rows;
    if (rows is Map) return [rows];
    return const [];
  }
}
