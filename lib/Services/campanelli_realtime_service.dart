import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_provider.dart';

abstract class CampanelliRealtimeSubscription {
  void close();
}

abstract class CampanelliRealtimeGateway {
  CampanelliRealtimeSubscription subscribeOwner({
    required String userId,
    required List<String> ownedHinooIds,
    required void Function(Map<String, dynamic> row) onPendingInsert,
    required void Function(String id) onDelete,
  });

  CampanelliRealtimeSubscription subscribeVisitor({
    required String userId,
    required void Function(String targetTag) onAccessGranted,
  });
}

class SupabaseCampanelliRealtimeGateway implements CampanelliRealtimeGateway {
  SupabaseCampanelliRealtimeGateway({SupabaseClient? client})
      : _client = client ?? SupabaseProvider.client;

  final SupabaseClient _client;

  @override
  CampanelliRealtimeSubscription subscribeOwner({
    required String userId,
    required List<String> ownedHinooIds,
    required void Function(Map<String, dynamic> row) onPendingInsert,
    required void Function(String id) onDelete,
  }) {
    _authenticateRealtime();
    final insertFilter = ownedHinooIds.isEmpty
        ? ChannelFilter(
            event: 'INSERT',
            schema: 'public',
            table: 'house_access',
          )
        : ChannelFilter(
            event: 'INSERT',
            schema: 'public',
            table: 'house_access',
            filter: 'target_house_tag=in.(${ownedHinooIds.join(',')})',
          );
    final ownedIds = ownedHinooIds.toSet();
    final channel = _client.channel('house-access-owner-$userId')
      ..on(
        RealtimeListenTypes.postgresChanges,
        insertFilter,
        (payload, [ref]) {
          final row = _record(payload, 'new');
          if (row == null || row['granted_at'] != null) return;
          final tag = row['target_house_tag']?.toString() ?? '';
          if (tag.isEmpty || !ownedIds.contains(tag)) return;
          onPendingInsert(row);
        },
      )
      ..on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: 'DELETE',
          schema: 'public',
          table: 'house_access',
        ),
        (payload, [ref]) {
          final id = _record(payload, 'old')?['id']?.toString() ?? '';
          if (id.isNotEmpty) onDelete(id);
        },
      )
      ..subscribe();
    return _SupabaseCampanelliRealtimeSubscription(channel);
  }

  @override
  CampanelliRealtimeSubscription subscribeVisitor({
    required String userId,
    required void Function(String targetTag) onAccessGranted,
  }) {
    _authenticateRealtime();
    final channel = _client.channel('house-access-visitor-$userId')
      ..on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: 'UPDATE',
          schema: 'public',
          table: 'house_access',
          filter: 'visitor_id=eq.$userId',
        ),
        (payload, [ref]) {
          final row = _record(payload, 'new');
          if (row == null || row['granted_at'] == null) return;
          final tag = row['target_house_tag']?.toString() ?? '';
          if (tag.isNotEmpty) onAccessGranted(tag);
        },
      )
      ..subscribe();
    return _SupabaseCampanelliRealtimeSubscription(channel);
  }

  void _authenticateRealtime() {
    final accessToken = _client.auth.currentSession?.accessToken;
    if (accessToken != null) _client.realtime.setAuth(accessToken);
  }

  static Map<String, dynamic>? _record(dynamic payload, String key) {
    if (payload is! Map || payload[key] is! Map) return null;
    return Map<String, dynamic>.from(payload[key] as Map);
  }
}

class _SupabaseCampanelliRealtimeSubscription
    implements CampanelliRealtimeSubscription {
  const _SupabaseCampanelliRealtimeSubscription(this._channel);

  final RealtimeChannel _channel;

  @override
  void close() {
    unawaited(_channel.unsubscribe());
  }
}
