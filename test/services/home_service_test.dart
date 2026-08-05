import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Services/home_service.dart';
import 'package:honoo/Utility/replies_seen_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_supabase_helper.dart';

void main() {
  setUpAll(registerSupabaseFallbacks);

  late SupabaseTestHarness harness;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    harness = SupabaseTestHarness(withAuthenticatedUser: true)
      ..enableOverrides();
  });

  tearDown(() => harness.disableOverrides());

  test('conta le risposte non lette separatamente per conversazione', () async {
    final honoo = harness.stubTable('honoo');
    final hinoo = harness.stubTable('hinoo');
    honoo.queueResponse(<Map<String, dynamic>>[
      {
        'created_at': '2026-08-03T11:00:00Z',
        'user_id': 'sender-1',
        'conversation_id': 'conversation-opened',
      },
      {
        'created_at': '2026-08-03T11:00:00Z',
        'user_id': 'sender-2',
        'conversation_id': 'conversation-unopened',
      },
    ]);
    hinoo.queueResponse(<Map<String, dynamic>>[]);
    await RepliesSeenTracker.markAt(
      DateTime.parse('2026-08-03T09:00:00Z'),
      userId: 'test_user',
    );
    await RepliesSeenTracker.markAt(
      DateTime.parse('2026-08-03T12:00:00Z'),
      userId: 'test_user',
      conversationId: 'conversation-opened',
    );

    final count = await const HomeService().fetchUnreadReplyCount('test_user');

    expect(count, 1);
  });

  test('al primo utilizzo considera non lette tutte le risposte', () async {
    final honoo = harness.stubTable('honoo');
    final hinoo = harness.stubTable('hinoo');
    honoo.queueResponse(<Map<String, dynamic>>[
      {
        'created_at': '2026-08-03T11:00:00Z',
        'user_id': 'sender-1',
        'conversation_id': 'conversation-1',
      },
    ]);
    hinoo.queueResponse(<Map<String, dynamic>>[
      {
        'created_at': '2026-08-03T12:00:00Z',
        'user_id': 'sender-2',
        'conversation_id': 'conversation-2',
      },
    ]);

    final count = await const HomeService().fetchUnreadReplyCount('test_user');

    expect(count, 2);
  });
}
