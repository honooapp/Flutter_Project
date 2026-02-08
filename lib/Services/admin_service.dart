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

  Future<List<AdminUserRecord>> fetchAllUsersWithEmails() async {
    final rows = await _client.rpc('admin_list_user_emails');
    final users = <AdminUserRecord>[];
    if (rows is List) {
      for (final row in rows) {
        if (row is! Map) continue;
        final String id = row['auth_user_id']?.toString() ?? '';
        if (id.isEmpty) continue;
        users.add(
          AdminUserRecord(
            authUserId: id,
            email: row['email']?.toString(),
          ),
        );
      }
    } else if (rows is Map) {
      final String id = rows['auth_user_id']?.toString() ?? '';
      if (id.isNotEmpty) {
        users.add(
          AdminUserRecord(
            authUserId: id,
            email: rows['email']?.toString(),
          ),
        );
      }
    }
    return users;
  }

  Future<Map<DateTime, int>> fetchRecentVisits({int days = 3}) async {
    final res = await _client.rpc(
      'admin_list_site_visits',
      params: {'p_days': days},
    );
    final Map<DateTime, int> visits = {};
    if (res is List) {
      for (final row in res) {
        if (row is! Map) continue;
        final dateValue = row['visit_date']?.toString() ?? '';
        final countValue = row['count'];
        if (dateValue.isEmpty) continue;
        final date = DateTime.tryParse(dateValue);
        if (date == null) continue;
        visits[DateTime(date.year, date.month, date.day)] =
            (countValue as num?)?.toInt() ?? 0;
      }
    }
    return visits;
  }

  Future<Map<String, int>> fetchTodayMoonCounts() async {
    final res = await _client.rpc('admin_moon_counts_today');
    int honooCount = 0;
    int hinooCount = 0;
    if (res is List && res.isNotEmpty) {
      final row = res.first;
      if (row is Map) {
        honooCount = (row['honoo_count'] as num?)?.toInt() ?? 0;
        hinooCount = (row['hinoo_count'] as num?)?.toInt() ?? 0;
      }
    } else if (res is Map) {
      honooCount = (res['honoo_count'] as num?)?.toInt() ?? 0;
      hinooCount = (res['hinoo_count'] as num?)?.toInt() ?? 0;
    }
    return {
      'honoo': honooCount,
      'hinoo': hinooCount,
    };
  }

  Future<Map<String, int>> fetchDailyContentCounts() async {
    final res = await _client.rpc('admin_daily_content_counts');
    final Map<String, int> counts = {
      'chest_honoo': 0,
      'chest_hinoo': 0,
      'moon_honoo': 0,
      'moon_hinoo': 0,
      'reply_honoo': 0,
      'reply_hinoo': 0,
    };
    Map? row;
    if (res is List && res.isNotEmpty && res.first is Map) {
      row = res.first as Map;
    } else if (res is Map) {
      row = res;
    }
    if (row != null) {
      counts['chest_honoo'] = (row['chest_honoo'] as num?)?.toInt() ?? 0;
      counts['chest_hinoo'] = (row['chest_hinoo'] as num?)?.toInt() ?? 0;
      counts['moon_honoo'] = (row['moon_honoo'] as num?)?.toInt() ?? 0;
      counts['moon_hinoo'] = (row['moon_hinoo'] as num?)?.toInt() ?? 0;
      counts['reply_honoo'] = (row['reply_honoo'] as num?)?.toInt() ?? 0;
      counts['reply_hinoo'] = (row['reply_hinoo'] as num?)?.toInt() ?? 0;
    }
    return counts;
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
        .select('user_id,status')
        .in_('user_id', userIds);

    final existing = <String>{};
    for (final row in (rows as List)) {
      if (row is! Map) continue;
      final String id = row['user_id']?.toString() ?? '';
      final String status = row['status']?.toString() ?? '';
      if (status == 'declined') continue;
      if (id.isNotEmpty) existing.add(id);
    }
    return existing;
  }

  Future<Set<String>> fetchExistingCaseOwners(List<String> userIds) async {
    if (userIds.isEmpty) return {};
    final rows = await _client
        .from('case')
        .select('owner_id')
        .in_('owner_id', userIds);

    final existing = <String>{};
    for (final row in (rows as List)) {
      if (row is! Map) continue;
      final String id = row['owner_id']?.toString() ?? '';
      if (id.isNotEmpty) existing.add(id);
    }
    return existing;
  }

  Future<int> inviteUsers({
    required String adminUid,
    required List<String> userIds,
    Map<String, String>? userEmails,
  }) async {
    final filtered = userIds.where((id) => id.trim().isNotEmpty).toList();
    if (filtered.isEmpty) return 0;

    final existing = await fetchExistingInvites(filtered);
    final existingCases = await fetchExistingCaseOwners(filtered);
    final toInsert = filtered
        .where((id) => !existing.contains(id) && !existingCases.contains(id))
        .toList();
    if (toInsert.isEmpty) return 0;

    final payload = toInsert
        .map(
          (id) => {
            'user_id': id,
            'invited_by': adminUid,
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
            if (userEmails != null && userEmails[id] != null)
              'email': userEmails[id],
          },
        )
        .toList();

    await _client.from('house_invites').insert(payload);
    if (userEmails != null) {
      for (final id in toInsert) {
        final email = userEmails[id];
        if (email == null || email.isEmpty) continue;
        await _sendInviteEmail(email);
      }
    }
    return toInsert.length;
  }

  Future<void> _sendInviteEmail(String email) async {
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        await _client.auth.signInWithOtp(
          email: email,
          shouldCreateUser: false,
        );
        return;
      } catch (e) {
        if (attempt == 1) rethrow;
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
  }
}
