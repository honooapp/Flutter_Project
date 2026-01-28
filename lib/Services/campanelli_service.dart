import '../Entities/casa_model.dart';
import '../Entities/house_invite_model.dart';

class CampanelliCollections {
  static const String caseCollection = 'case';
  static const String houseInvites = 'house_invites';
}

abstract class CampanelliRepository {
  Future<bool> isAdmin(String uid);
  Future<void> createHouseInvite(HouseInviteModel invite);
  Future<HouseInviteModel?> getInviteForUser(String uid);
  Future<HouseInviteModel?> getInviteForEmail(String email);
  Future<bool> hasCasa(String uid);
  Future<void> saveCasa(CasaModel casa);
}

class CampanelliService {
  CampanelliService(this.repository);

  final CampanelliRepository repository;

  Future<void> sendHouseInvite({
    required String adminUid,
    String? email,
    String? userId,
  }) async {
    if (!await repository.isAdmin(adminUid)) {
      throw Exception('Admin permissions required.');
    }

    if (email == null && userId == null) {
      throw Exception('Missing invite target.');
    }

    final invite = HouseInviteModel(
      id: _inviteId(email, userId),
      invitedBy: adminUid,
      email: email,
      userId: userId,
      status: HouseInviteStatus.pending,
      createdAt: DateTime.now(),
    );

    await repository.createHouseInvite(invite);
  }

  Future<bool> canCreateHouse({
    required String uid,
  }) async {
    if (await repository.hasCasa(uid)) return false;

    final HouseInviteModel? invite = await repository.getInviteForUser(uid);

    if (invite == null) return false;
    if (invite.status != HouseInviteStatus.accepted) return false;

    return true;
  }

  String _inviteId(String? email, String? userId) {
    if (email != null) return email;
    return userId ?? '';
  }
}
