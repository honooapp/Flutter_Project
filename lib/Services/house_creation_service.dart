import 'package:honoo/Services/supabase_provider.dart';

enum HouseCreationStatus {
  noInvite,
  invitePending,
  canCreateCasa,
  alreadyHasCasa,
}

class HouseCreationService {
  const HouseCreationService();

  Future<HouseCreationStatus> getHouseCreationStatus() async {
    final user = SupabaseProvider.client.auth.currentUser;
    if (user == null) {
      return HouseCreationStatus.noInvite;
    }

    final String uid = user.id;
    final List<dynamic> existingCasa = await SupabaseProvider.client
        .from('case')
        .select('id')
        .eq('owner_id', uid)
        .limit(1);
    if (existingCasa.isNotEmpty) {
      return HouseCreationStatus.alreadyHasCasa;
    }

    final List<dynamic> invitesByUser = await SupabaseProvider.client
        .from('house_invites')
        .select('status')
        .eq('user_id', uid);

    if (invitesByUser.isEmpty) {
      return HouseCreationStatus.noInvite;
    }

    final bool hasAcceptedInvite =
        invitesByUser.any((row) => row is Map && row['status'] == 'accepted');
    if (!hasAcceptedInvite) {
      return HouseCreationStatus.invitePending;
    }
    return HouseCreationStatus.canCreateCasa;
  }
}
