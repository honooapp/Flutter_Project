import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_provider.dart';

abstract class ChestRealtimeSubscription {
  Future<void> close();
}

enum ChestRealtimeConnectionStatus {
  subscribed,
  disconnected,
}

abstract class ChestRealtimeGateway {
  ChestRealtimeSubscription subscribe({
    required String userId,
    required void Function() onChange,
    required void Function(
      ChestRealtimeConnectionStatus status,
      Object? error,
    ) onStatus,
  });
}

class SupabaseChestRealtimeGateway implements ChestRealtimeGateway {
  SupabaseChestRealtimeGateway({SupabaseClient? client})
      : _client = client ?? SupabaseProvider.client;

  final SupabaseClient _client;

  @override
  ChestRealtimeSubscription subscribe({
    required String userId,
    required void Function() onChange,
    required void Function(
      ChestRealtimeConnectionStatus status,
      Object? error,
    ) onStatus,
  }) {
    void notify(dynamic _, [dynamic __]) => onChange();
    final accessToken = _client.auth.currentSession?.accessToken;
    if (accessToken != null) _client.realtime.setAuth(accessToken);

    final channel = _client.channel('chest-replies-$userId');
    channel.on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(event: '*', schema: 'public', table: 'honoo'),
      notify,
    );
    channel.on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(event: '*', schema: 'public', table: 'hinoo'),
      notify,
    );
    channel.subscribe((status, [error]) {
      if (status == 'SUBSCRIBED') {
        onStatus(ChestRealtimeConnectionStatus.subscribed, null);
        return;
      }
      if (status == 'CHANNEL_ERROR' ||
          status == 'CLOSED' ||
          status == 'TIMED_OUT') {
        onStatus(ChestRealtimeConnectionStatus.disconnected, error ?? status);
      }
    });
    return _SupabaseChestRealtimeSubscription(channel);
  }
}

class _SupabaseChestRealtimeSubscription implements ChestRealtimeSubscription {
  const _SupabaseChestRealtimeSubscription(this._channel);

  final RealtimeChannel _channel;

  @override
  Future<void> close() async {
    await _channel.unsubscribe();
  }
}
