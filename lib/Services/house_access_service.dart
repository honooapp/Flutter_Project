import 'supabase_provider.dart';

class HouseAccessService {
  const HouseAccessService();

  Future<void> sendKnock({
    required String targetHouseTag,
    required String visitorId,
    String? hinooId,
    String? honooId,
  }) {
    return SupabaseProvider.client.from('house_access').insert({
      'target_house_tag': targetHouseTag,
      'visitor_id': visitorId,
      if (hinooId != null && hinooId.isNotEmpty) 'hinoo_id': hinooId,
      if (honooId != null && honooId.isNotEmpty) 'honoo_id': honooId,
    });
  }

  Future<void> saveShareModes({
    required String ownerId,
    required String campanelloHinooId,
    required List<String> modes,
  }) {
    return SupabaseProvider.client.from('house_share_settings').upsert({
      'owner_id': ownerId,
      'campanello_hinoo_id': campanelloHinooId,
      'share_mode': modes.isEmpty ? null : modes.first,
      'share_modes': modes,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'campanello_hinoo_id');
  }
}
