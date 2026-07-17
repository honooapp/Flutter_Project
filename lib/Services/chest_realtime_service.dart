import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_provider.dart';

abstract class ChestRealtimeSubscription {
  void close();
}

abstract class ChestRealtimeGateway {
  ChestRealtimeSubscription subscribe({
    required String userId,
    required void Function() onChange,
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
  }) {
    void notify(dynamic _, [dynamic __]) => onChange();

    final channel = _client.channel('chest-replies-$userId')
      ..on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(event: '*', schema: 'public', table: 'honoo'),
        notify,
      )
      ..on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(event: '*', schema: 'public', table: 'hinoo'),
        notify,
      )
      ..subscribe();
    return _SupabaseChestRealtimeSubscription(channel);
  }
}

class _SupabaseChestRealtimeSubscription implements ChestRealtimeSubscription {
  const _SupabaseChestRealtimeSubscription(this._channel);

  final RealtimeChannel _channel;

  @override
  void close() {
    unawaited(_channel.unsubscribe());
  }
}
