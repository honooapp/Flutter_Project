import 'package:honoo/Services/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUserRecord {
  final String authUserId;
  final String? email;

  const AdminUserRecord({required this.authUserId, this.email});
}

class AdminService {
  AdminService({SupabaseClient? client})
      : _client = client ?? SupabaseProvider.client;

  final SupabaseClient _client;

  Future<bool> isCurrentUserAdmin() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final res = await _client
        .from('users')
        .select('is_admin')
        .eq('auth_user_id', user.id)
        .limit(1)
        .maybeSingle();
    if (res == null) return false;
    return res['is_admin'] == true;
  }

  Future<List<AdminUserRecord>> fetchAllUsers() async {
    final rows = await _client
        .from('users')
        .select('auth_user_id,email');

    final users = <AdminUserRecord>[];
    for (final row in (rows as List)) {
      if (row is! Map) continue;
      final String id = row['auth_user_id']?.toString() ?? '';
      if (id.isEmpty) continue;
      final String? email = row['email']?.toString();
      users.add(AdminUserRecord(authUserId: id, email: email));
    }
    return users;
  }

  Future<AdminUserRecord?> findUserByEmail(String email) async {
    final res = await _client
        .rpc('admin_find_user_by_email', params: {'p_email': email});
    if (res == null) return null;
    if (res is List && res.isNotEmpty) {
      final row = res.first;
      if (row is! Map) return null;
      final String id = row['auth_user_id']?.toString() ?? '';
      if (id.isEmpty) return null;
      return AdminUserRecord(authUserId: id, email: row['email']?.toString());
    }
    if (res is Map) {
      final String id = res['auth_user_id']?.toString() ?? '';
      if (id.isEmpty) return null;
      return AdminUserRecord(authUserId: id, email: res['email']?.toString());
    }
    return null;
  }

  Future<Set<String>> fetchExistingInvites(List<String> userIds) async {
    if (userIds.isEmpty) return {};
    final rows = await _client
        .from('house_invites')
        .select('user_id')
        .in_('user_id', userIds);

    final existing = <String>{};
    for (final row in (rows as List)) {
      if (row is! Map) continue;
      final String id = row['user_id']?.toString() ?? '';
      if (id.isNotEmpty) existing.add(id);
    }
    return existing;
  }

  Future<int> inviteUsers({
    required String adminUid,
    required List<String> userIds,
  }) async {
    final filtered = userIds.where((id) => id.trim().isNotEmpty).toList();
    if (filtered.isEmpty) return 0;

    final existing = await fetchExistingInvites(filtered);
    final toInsert = filtered.where((id) => !existing.contains(id)).toList();
    if (toInsert.isEmpty) return 0;

    final payload = toInsert
        .map(
          (id) => {
            'user_id': id,
            'invited_by': adminUid,
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
          },
        )
        .toList();

    await _client.from('house_invites').insert(payload);
    return toInsert.length;
  }
}
