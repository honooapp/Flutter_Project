import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_provider.dart';

/// Accesso ai dati necessari per costruire l’elenco dei Campanelli.
/// Mapping, ordinamento e stato UI restano fuori dal repository.
class CampanelliDataRepository {
  CampanelliDataRepository({SupabaseClient? client})
      : _client = client ?? SupabaseProvider.client;

  final SupabaseClient _client;

  Future<List<dynamic>> fetchHouseRows() async {
    final rows = await _client
        .from('case')
        .select('campanello_hinoo_id,owner_id,house_image_url,bg_transform');
    return _asList(rows);
  }

  Future<List<dynamic>> fetchShareSettingsRows(List<String> hinooIds) async {
    if (hinooIds.isEmpty) return const [];
    final rows = await _client
        .from('house_share_settings')
        .select('campanello_hinoo_id,share_mode,share_modes')
        .in_('campanello_hinoo_id', hinooIds);
    return _asList(rows);
  }

  Future<List<dynamic>> fetchHinooRows(List<String> hinooIds) async {
    if (hinooIds.isEmpty) return const [];
    final rows =
        await _client.from('hinoo').select('id,pages').in_('id', hinooIds);
    return _asList(rows);
  }

  Future<List<dynamic>> fetchPendingKnockRows(
    List<String> targetHouseTags,
  ) async {
    if (targetHouseTags.isEmpty) return const [];
    final rows = await _client
        .from('house_access')
        .select('id,target_house_tag,created_at,hinoo_id,honoo_id')
        .in_('target_house_tag', targetHouseTags)
        .is_('granted_at', null);
    return _asList(rows);
  }

  Future<Map<String, dynamic>?> fetchHinooForKnock(String hinooId) async {
    final row = await _client
        .from('hinoo')
        .select('pages,type,recipient_tag,created_at')
        .eq('id', hinooId)
        .maybeSingle();
    return _asMap(row);
  }

  Future<Map<String, dynamic>?> fetchHonooForKnock(String honooId) async {
    final row = await _client
        .from('honoo')
        .select(
          'id,text,image_url,destination,reply_to,recipient_tag,created_at,updated_at,user_id',
        )
        .eq('id', honooId)
        .maybeSingle();
    return _asMap(row);
  }

  Future<void> grantHouseAccess({
    required String knockId,
    required DateTime grantedAt,
  }) async {
    await _client.from('house_access').update({
      'granted_at': grantedAt.toIso8601String(),
    }).eq('id', knockId);
  }

  static List<dynamic> _asList(dynamic rows) {
    if (rows is List) return rows;
    if (rows is Map) return [rows];
    return const [];
  }

  static Map<String, dynamic>? _asMap(dynamic row) {
    if (row is Map<String, dynamic>) return row;
    if (row is Map) return Map<String, dynamic>.from(row);
    return null;
  }
}
