import 'package:honoo/Services/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HouseInviteService {
  HouseInviteService({SupabaseClient? client})
      : _client = client ?? SupabaseProvider.client;

  final SupabaseClient _client;

  Future<bool> hasCasa(String userId) async {
    final rows = await _client
        .from('case')
        .select('id')
        .eq('owner_id', userId)
        .limit(1);
    return rows is List && rows.isNotEmpty;
  }

  Future<bool> hasPendingOrAcceptedInvite(String userId) async {
    final rows = await _client
        .from('house_invites')
        .select('status')
        .eq('user_id', userId)
        .in_('status', ['pending', 'accepted'])
        .limit(1);
    if (rows is! List || rows.isEmpty) return false;
    final row = rows.first;
    if (row is! Map) return false;
    final status = row['status']?.toString();
    return status == 'pending' || status == 'accepted';
  }

  Future<void> syncInvitesForEmail(String email) async {
    if (email.trim().isEmpty) return;
    await _client.rpc(
      'claim_house_invite_by_email',
      params: {'p_email': email},
    );
  }

  Future<void> markInvitesAccepted(String userId) async {
    await _client
        .from('house_invites')
        .update({'status': 'accepted'})
        .eq('user_id', userId);
  }

  Future<void> markInvitesDeclined(String userId) async {
    await _client
        .from('house_invites')
        .update({'status': 'declined'})
        .eq('user_id', userId);
  }
}
