import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Entities/conversation_entry.dart';
import 'package:honoo/Services/conversation_service.dart';
import 'package:mocktail/mocktail.dart';

import '../test_supabase_helper.dart';

void main() {
  setUpAll(registerSupabaseFallbacks);

  late SupabaseTestHarness harness;

  setUp(() {
    harness = SupabaseTestHarness(withAuthenticatedUser: true)
      ..enableOverrides();
  });

  tearDown(() {
    harness.disableOverrides();
    resetMocktailState();
  });

  test('ordina honoo e hinoo usando il created_at reale', () async {
    final honoo = harness.stubTable('honoo');
    final hinoo = harness.stubTable('hinoo');
    honoo.queueResponse(<Map<String, dynamic>>[
      {
        'id': 'honoo-1',
        'text': 'prima',
        'image_url': '',
        'destination': 'chest',
        'created_at': '2026-01-01T10:00:00Z',
        'updated_at': '2026-01-01T10:00:00Z',
        'user_id': 'user-1',
        'conversation_id': 'conversation-1',
      },
    ]);
    hinoo.queueResponse(<Map<String, dynamic>>[
      {
        'id': 'hinoo-1',
        'pages': <Map<String, dynamic>>[
          {
            'text': 'seconda',
            'backgroundImage': 'bg.png',
            'isTextWhite': true,
          },
        ],
        'type': 'answer',
        'created_at': '2026-01-01T11:00:00Z',
        'user_id': 'user-2',
        'conversation_id': 'conversation-1',
      },
    ]);

    final result =
        await ConversationService.fetchConversation('conversation-1');

    expect(result.map((entry) => entry.kind), [
      ConversationEntryKind.honoo,
      ConversationEntryKind.hinoo,
    ]);
    expect(result.last.createdAt, DateTime.parse('2026-01-01T11:00:00Z'));
    verify(() => honoo.eq('conversation_id', 'conversation-1')).called(1);
    verify(() => hinoo.eq('conversation_id', 'conversation-1')).called(1);
  });

  test('riconosce una vecchia risposta Hinoo anche senza reply_to', () async {
    final honoo = harness.stubTable('honoo');
    final hinoo = harness.stubTable('hinoo');
    honoo.queueResponse(<Map<String, dynamic>>[]);
    hinoo.queueResponse(<Map<String, dynamic>>[
      {
        'id': 'hinoo-legacy-reply',
        'pages': <Map<String, dynamic>>[
          {
            'text': 'risposta',
            'backgroundImage': 'bg.png',
            'isTextWhite': true,
          },
        ],
        'type': 'personal',
        'reply_to': null,
        'recipient_tag': 'recipient-1',
        'conversation_id': 'conversation-1',
        'created_at': '2026-01-01T11:00:00Z',
        'user_id': 'user-2',
        'is_from_moon_saved': false,
      },
    ]);

    final result =
        await ConversationService.fetchConversation('conversation-1');

    expect(result.single.hinoo!.type.name, 'answer');
  });
}
