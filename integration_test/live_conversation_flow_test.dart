import 'dart:async';

import 'package:honoo/testing/live_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  test('LIVE: quattro incroci, RLS, ordine e Realtime', () async {
    if (!LiveConfig.liveRun) return;
    expect(LiveConfig.hasConversationUsers, isTrue,
        reason: 'Configurazione dei due utenti live incompleta');

    final a = SupabaseClient(LiveConfig.supaUrl, LiveConfig.supaAnon);
    final b = SupabaseClient(LiveConfig.supaUrl, LiveConfig.supaAnon);
    final marker = 'codex-conversation-${DateTime.now().microsecondsSinceEpoch}';
    final createdHonoo = <String>[];
    final createdHinoo = <String>[];
    RealtimeChannel? channel;

    await a.auth.signInWithPassword(
      email: LiveConfig.userAEmail,
      password: LiveConfig.userAPassword,
    );
    await b.auth.signInWithPassword(
      email: LiveConfig.userBEmail,
      password: LiveConfig.userBPassword,
    );
    final aId = a.auth.currentUser!.id;

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
      final honooRoot = await insertHonoo(
        a,
        text: 'root honoo',
        destination: 'chest',
      );
      final honooRootId = honooRoot['id'].toString();
      final honooConversationId = honooRoot['conversation_id'].toString();
      expect(honooConversationId, honooRootId,
          reason: 'La radice honoo deve inizializzare conversation_id col suo id');

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
          reason: 'La radice hinoo deve inizializzare conversation_id col suo id');

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
      final realtime = Completer<void>();
      final subscribed = Completer<void>();
      channel = a.channel('live-test-$marker')
        ..on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: 'INSERT',
            schema: 'public',
            table: 'honoo',
            filter: 'conversation_id=eq.$honooConversationId',
          ),
          (_, [__]) {
            if (!realtime.isCompleted) realtime.complete();
          },
        );
      channel.subscribe((status, [error]) {
        if (status == 'SUBSCRIBED' && !subscribed.isCompleted) {
          subscribed.complete();
        } else if ((status == 'CHANNEL_ERROR' || status == 'TIMED_OUT') &&
            !subscribed.isCompleted) {
          subscribed.completeError(
            StateError('Sottoscrizione Realtime fallita: $status'),
          );
        }
      });
      await subscribed.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () => throw StateError(
          'Il canale Realtime non ha raggiunto SUBSCRIBED',
        ),
      );
      await insertHonoo(
        b,
        text: 'realtime check',
        destination: 'reply',
        replyTo: honooRootId,
        conversationId: honooConversationId,
        recipientTag: aId,
      );
      await realtime.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () => throw StateError(
          'Canale sottoscritto, ma evento INSERT non ricevuto',
        ),
      );
    } finally {
      if (channel != null) await channel.unsubscribe();
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
      await a.dispose();
      await b.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
