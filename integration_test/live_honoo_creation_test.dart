import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:honoo/main.dart' as app;
import 'package:honoo/testing/live_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('LIVE/E2E: boot UI + Supabase ping + login + storage check',
      (tester) async {
    // ignore: avoid_print
    print(
        'DBG live=${LiveConfig.liveRun} url_len=${LiveConfig.supaUrl.length} key_len=${LiveConfig.supaAnon.length} email_len=${LiveConfig.email.length}');

    try {
      app.main();
    } catch (_) {}

    await tester.pumpAndSettle(const Duration(seconds: 12));

    expect(find.byType(MaterialApp), findsWidgets,
        reason: 'UI non visibile: init forse blocca runApp');

    if (!LiveConfig.liveRun) {
      // ignore: avoid_print
      print('DBG: HONOO_LIVE_RUN=false -> salto sezione live');
      return;
    }

    expect(LiveConfig.isValid, isTrue, reason: 'Dart-define HONOO_* mancanti');

    final supa = SupabaseClient(LiveConfig.supaUrl, LiveConfig.supaAnon);

    await tester.runAsync(() async {
      try {
        final pong = await supa.from('honoo').select('id').limit(1);
        // ignore: avoid_print
        print('DBG supabase ping ok, rows=${pong.length}');
      } catch (e) {
        fail('Supabase ping fallito: $e');
      }

      try {
        final auth = await supa.auth.signInWithPassword(
          email: LiveConfig.email,
          password: LiveConfig.pass,
        );
        expect(auth.session, isNotNull, reason: 'login senza sessione');
        // ignore: avoid_print
        print('DBG login ok, has_session=${auth.session != null}');
      } catch (e) {
        fail('Login fallito: $e');
      }

      final client = HttpClient();
      try {
        final uri = Uri.parse(LiveConfig.testImageUrl);
        final request = await client.getUrl(uri);
        final response = await request.close();
        if (response.statusCode != 200) {
          fail('Storage access fallito: status=${response.statusCode}');
        }
        // ignore: avoid_print
        print('DBG storage get ok status=${response.statusCode}');
      } catch (e) {
        fail('Storage access fallito: $e');
      } finally {
        client.close(force: true);
      }
    });

    await tester.pump(const Duration(milliseconds: 300));
  });
}
