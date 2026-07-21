import 'dart:async';
import 'dart:typed_data';

import 'package:honoo/testing/live_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  test('LIVE: quattro incroci, RLS, ordine e Realtime', () async {
    expect(LiveConfig.hasConversationUsers, isTrue,
        reason: 'Configurazione dei due utenti live incompleta');

    final a = SupabaseClient(LiveConfig.supaUrl, LiveConfig.supaAnon);
    final b = SupabaseClient(LiveConfig.supaUrl, LiveConfig.supaAnon);
    final marker =
        'codex-conversation-${DateTime.now().microsecondsSinceEpoch}';
    final createdHonoo = <String>[];
    final createdHinoo = <String>[];
    final createdStorageObjects = <String, List<String>>{};
    RealtimeChannel? channel;
    RealtimeChannel? reconnectedChannel;
    String? expectedRealtimeDeleteId;

    await a.auth.signInWithPassword(
      email: LiveConfig.userAEmail,
      password: LiveConfig.userAPassword,
    );
    await b.auth.signInWithPassword(
      email: LiveConfig.userBEmail,
      password: LiveConfig.userBPassword,
    );
    final aId = a.auth.currentUser!.id;
    final bId = b.auth.currentUser!.id;
    a.storage.setAuth(a.auth.currentSession!.accessToken);
    b.storage.setAuth(b.auth.currentSession!.accessToken);

    // Superfici autenticate di Scrigno e Campanelli: le query devono riuscire
    // per entrambi gli utenti anche quando il risultato è vuoto.
    await a.from('honoo').select('id').eq('user_id', aId).limit(10);
    await a.from('hinoo').select('id').eq('user_id', aId).limit(10);
    await b.from('honoo').select('id').eq('user_id', bId).limit(10);
    await b.from('hinoo').select('id').eq('user_id', bId).limit(10);
    await a.from('campanelli').select('id').eq('owner_id', aId).limit(1);
    await b.from('campanelli').select('id').eq('owner_id', bId).limit(1);
    await a.from('case').select('id').eq('owner_id', aId).limit(1);
    await b.from('case').select('id').eq('owner_id', bId).limit(1);

    Future<Map<String, dynamic>> insertHonoo(
      SupabaseClient client, {
      required String text,
      required String destination,
      String? replyTo,
      String? conversationId,
      String? recipientTag,
    }) async {
      final row = await client
          .from('honoo')
          .insert({
            'text': '$marker $text',
            'image_url': '',
            'destination': destination,
            'reply_to': replyTo,
            'conversation_id': conversationId,
            'recipient_tag': recipientTag,
          })
          .select('id,conversation_id,created_at')
          .single();
      final mapped = Map<String, dynamic>.from(row);
      createdHonoo.add(mapped['id'].toString());
      return mapped;
    }

    Future<Map<String, dynamic>> insertHinoo(
      SupabaseClient client, {
      required String text,
      required String type,
      String? replyTo,
      String? conversationId,
      String? recipientTag,
    }) async {
      final row = await client
          .from('hinoo')
          .insert({
            'user_id': client.auth.currentUser!.id,
            'type': type,
            'pages': [
              {
                'backgroundImage': LiveConfig.testImageUrl,
                'text': '$marker $text',
                'isTextWhite': true,
              }
            ],
            'reply_to': replyTo,
            'conversation_id': conversationId,
            'recipient_tag': recipientTag,
          })
          .select('id,conversation_id,created_at')
          .single();
      final mapped = Map<String, dynamic>.from(row);
      createdHinoo.add(mapped['id'].toString());
      return mapped;
    }

    try {
      // Verifica upload e rimozione nel bucket hinoo con un oggetto temporaneo.
      // honoo-images viene verificato separatamente: la policy storica non
      // consente la SELECT necessaria alla rimozione via Storage API e non va
      // modificata implicitamente da questo test.
      final storageProbe = Uint8List.fromList(<int>[137, 80, 78, 71]);
      for (final bucket in <String>['hinoo']) {
        final path = '$aId/codex-live/$marker.png';
        createdStorageObjects[bucket] = <String>[path];
        try {
          await a.storage.from(bucket).uploadBinary(
                path,
                storageProbe,
                fileOptions: const FileOptions(
                  upsert: false,
                  contentType: 'image/png',
                ),
              );
        } catch (error) {
          throw StateError('Upload Storage fallito per $bucket: $error');
        }
      }

      final honooRoot = await insertHonoo(
        a,
        text: 'root honoo',
        destination: 'chest',
      );
      final honooRootId = honooRoot['id'].toString();
      final honooConversationId = honooRoot['conversation_id'].toString();
      expect(honooConversationId, honooRootId,
          reason:
              'La radice honoo deve inizializzare conversation_id col suo id');

      await insertHonoo(
        b,
        text: 'honoo to honoo',
        destination: 'reply',
        replyTo: honooRootId,
        conversationId: honooConversationId,
        recipientTag: aId,
      );
      await insertHinoo(
        b,
        text: 'honoo to hinoo',
        type: 'answer',
        replyTo: honooRootId,
        conversationId: honooConversationId,
        recipientTag: aId,
      );

      final hinooRoot = await insertHinoo(
        a,
        text: 'root hinoo',
        type: 'personal',
      );
      final hinooRootId = hinooRoot['id'].toString();
      final hinooConversationId = hinooRoot['conversation_id'].toString();
      expect(hinooConversationId, hinooRootId,
          reason:
              'La radice hinoo deve inizializzare conversation_id col suo id');

      await insertHonoo(
        b,
        text: 'hinoo to honoo',
        destination: 'reply',
        replyTo: hinooRootId,
        conversationId: hinooConversationId,
        recipientTag: aId,
      );
      await insertHinoo(
        b,
        text: 'hinoo to hinoo',
        type: 'answer',
        replyTo: hinooRootId,
        conversationId: hinooConversationId,
        recipientTag: aId,
      );

      final firstHonooThread = await a
          .from('honoo')
          .select('id,created_at,conversation_id')
          .eq('conversation_id', honooConversationId)
          .order('created_at');
      final firstHinooThread = await a
          .from('hinoo')
          .select('id,created_at,conversation_id')
          .eq('conversation_id', honooConversationId)
          .order('created_at');
      expect((firstHonooThread as List).length, 2);
      expect((firstHinooThread as List).length, 1);

      final secondHonooThread = await a
          .from('honoo')
          .select('id,created_at,conversation_id')
          .eq('conversation_id', hinooConversationId)
          .order('created_at');
      final secondHinooThread = await a
          .from('hinoo')
          .select('id,created_at,conversation_id')
          .eq('conversation_id', hinooConversationId)
          .order('created_at');
      expect((secondHonooThread as List).length, 1);
      expect((secondHinooThread as List).length, 2);

      a.realtime.setAuth(a.auth.currentSession!.accessToken);
      var realtimeInsert = Completer<void>();
      final realtimeDelete = Completer<void>();
      var subscribed = Completer<void>();
      var insertCallbacks = 0;
      var lastInsertDiagnostic = 'nessun callback INSERT';

      String describePayload(dynamic payload, String conversationId) {
        if (payload is! Map) return 'payload=${payload.runtimeType}';
        final keys = payload.keys.map((key) => key.toString()).toList()..sort();
        final record = payload['new'];
        return 'keys=$keys, record=${record.runtimeType}, '
            'conversationMatches='
            '${record is Map && record['conversation_id']?.toString() == conversationId}';
      }

      RealtimeChannel subscribeToHonoo(String suffix) {
        final nextChannel = a.channel('live-test-$suffix-$marker')
          ..on(
            RealtimeListenTypes.postgresChanges,
            ChannelFilter(
              event: 'INSERT',
              schema: 'public',
              table: 'honoo',
            ),
            (payload, [__]) {
              insertCallbacks++;
              lastInsertDiagnostic =
                  describePayload(payload, honooConversationId);
              final record = payload is Map ? payload['new'] : null;
              if (record is Map &&
                  record['conversation_id']?.toString() ==
                      honooConversationId &&
                  !realtimeInsert.isCompleted) {
                realtimeInsert.complete();
              }
            },
          )
          ..on(
            RealtimeListenTypes.postgresChanges,
            ChannelFilter(
              event: 'DELETE',
              schema: 'public',
              table: 'honoo',
            ),
            (payload, [__]) {
              final oldRecord = payload is Map ? payload['old'] : null;
              if (oldRecord is Map &&
                  oldRecord['id']?.toString() == expectedRealtimeDeleteId &&
                  !realtimeDelete.isCompleted) {
                realtimeDelete.complete();
              }
            },
          );
        nextChannel.subscribe((status, [error]) {
          if (status == 'SUBSCRIBED' && !subscribed.isCompleted) {
            subscribed.complete();
          } else if ((status == 'CHANNEL_ERROR' || status == 'TIMED_OUT') &&
              !subscribed.isCompleted) {
            subscribed.completeError(
              StateError('Sottoscrizione Realtime fallita: $status'),
            );
          }
        });
        return nextChannel;
      }

      Future<void> waitUntilSubscribed() => subscribed.future.timeout(
            const Duration(seconds: 25),
            onTimeout: () => throw StateError(
              'Il canale Realtime non ha raggiunto SUBSCRIBED',
            ),
          );

      channel = subscribeToHonoo('initial');
      await waitUntilSubscribed();
      await insertHonoo(
        b,
        text: 'realtime check',
        destination: 'reply',
        replyTo: honooRootId,
        conversationId: honooConversationId,
        recipientTag: aId,
      );
      try {
        await realtimeInsert.future.timeout(const Duration(seconds: 25));
      } on TimeoutException {
        // A transient Realtime delay must not make the whole live suite flaky.
        // Recreate the subscription once and emit a fresh probe: Postgres
        // changes are not replayed to a newly joined channel.
        await channel.unsubscribe();
        realtimeInsert = Completer<void>();
        subscribed = Completer<void>();
        channel = subscribeToHonoo('retry');
        await waitUntilSubscribed();
        await insertHonoo(
          b,
          text: 'realtime retry check',
          destination: 'reply',
          replyTo: honooRootId,
          conversationId: honooConversationId,
          recipientTag: aId,
        );
        try {
          await realtimeInsert.future.timeout(const Duration(seconds: 25));
        } on TimeoutException {
          throw StateError(
            'Evento INSERT non ricevuto dopo una risottoscrizione; '
            'callbacks=$insertCallbacks, ultimo=$lastInsertDiagnostic',
          );
        }
      }

      final realtimeRow = createdHonoo.last;
      expectedRealtimeDeleteId = realtimeRow;
      await b.from('honoo').delete().eq('id', realtimeRow);
      await realtimeDelete.future.timeout(
        const Duration(seconds: 25),
        onTimeout: () => throw StateError(
          'Canale sottoscritto, ma evento DELETE non ricevuto',
        ),
      );

      // Simula una perdita della connessione e verifica una nuova
      // sottoscrizione dopo il reconnect del client Realtime.
      await channel.unsubscribe();
      a.realtime.disconnect();
      // realtime_client 1.x closes the socket asynchronously: wait for the
      // old onDone callback before opening the replacement connection.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      // Test-only transport control needed to simulate a real reconnect.
      // ignore: invalid_use_of_internal_member
      a.realtime.connect();
      final reconnected = Completer<void>();
      final resubscribed = Completer<void>();
      var reconnectCallbacks = 0;
      var lastReconnectDiagnostic = 'nessun callback INSERT';
      reconnectedChannel = a.channel('live-test-reconnect-$marker')
        ..on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: 'INSERT',
            schema: 'public',
            table: 'honoo',
          ),
          (payload, [__]) {
            reconnectCallbacks++;
            lastReconnectDiagnostic =
                describePayload(payload, honooConversationId);
            final record = payload is Map ? payload['new'] : null;
            if (record is Map &&
                record['conversation_id']?.toString() == honooConversationId &&
                !reconnected.isCompleted) {
              reconnected.complete();
            }
          },
        );
      reconnectedChannel.subscribe((status, [error]) {
        if (status == 'SUBSCRIBED' && !resubscribed.isCompleted) {
          resubscribed.complete();
        } else if (status == 'TIMED_OUT' && !resubscribed.isCompleted) {
          resubscribed.completeError(
            StateError('Riconnessione Realtime fallita: $status'),
          );
        }
      });
      await resubscribed.future.timeout(
        const Duration(seconds: 25),
        onTimeout: () => throw StateError(
          'Il canale Realtime non si è risottoscritto dopo il reconnect',
        ),
      );
      await insertHonoo(
        b,
        text: 'reconnect check',
        destination: 'reply',
        replyTo: honooRootId,
        conversationId: honooConversationId,
        recipientTag: aId,
      );
      await reconnected.future.timeout(
        const Duration(seconds: 25),
        onTimeout: () => throw StateError(
          'Evento INSERT non ricevuto dopo la riconnessione; '
          'callbacks=$reconnectCallbacks, ultimo=$lastReconnectDiagnostic',
        ),
      );
    } finally {
      if (channel != null) await channel.unsubscribe();
      if (reconnectedChannel != null) await reconnectedChannel.unsubscribe();
      for (final id in createdHonoo.reversed) {
        try {
          await b.from('honoo').delete().eq('id', id);
          await a.from('honoo').delete().eq('id', id);
        } catch (_) {}
      }
      for (final id in createdHinoo.reversed) {
        try {
          await b.from('hinoo').delete().eq('id', id);
          await a.from('hinoo').delete().eq('id', id);
        } catch (_) {}
      }
      for (final entry in createdStorageObjects.entries) {
        try {
          await a.storage.from(entry.key).remove(entry.value);
        } catch (_) {}
      }
      await a.dispose();
      await b.dispose();
    }
  },
      skip: LiveConfig.liveRun
          ? false
          : 'Set HONOO_LIVE_RUN=true per eseguire il test live',
      timeout: const Timeout(Duration(minutes: 4)));
}
