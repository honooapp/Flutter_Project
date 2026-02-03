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
    final res = await _client.rpc('admin_is_admin');
    if (res is bool) return res;
    if (res is Map && res['admin_is_admin'] is bool) {
      return res['admin_is_admin'] as bool;
    }
    return res == true;
  }

  Future<List<AdminUserRecord>> fetchAllUsers() async {
    final rows = await _client.rpc('admin_list_users');

    final users = <AdminUserRecord>[];
    if (rows is List) {
      for (final row in rows) {
        if (row is! Map) continue;
        final String id = row['auth_user_id']?.toString() ?? '';
        if (id.isEmpty) continue;
        users.add(AdminUserRecord(authUserId: id));
      }
    } else if (rows is Map) {
      final String id = rows['auth_user_id']?.toString() ?? '';
      if (id.isNotEmpty) {
        users.add(AdminUserRecord(authUserId: id));
      }
    }
    return users;
  }

  Future<List<String>> fetchUserEmails() async {
    final rows = await _client.rpc('admin_list_user_emails');
    final emails = <String>[];
    if (rows is List) {
      for (final row in rows) {
        if (row is! Map) continue;
        final String email = row['email']?.toString() ?? '';
        if (email.isNotEmpty) emails.add(email);
      }
    } else if (rows is Map) {
      final String email = rows['email']?.toString() ?? '';
      if (email.isNotEmpty) emails.add(email);
    }
    return emails;
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
