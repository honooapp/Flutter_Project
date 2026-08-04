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
    harness.stubTable('conversation_tombstones');
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
          {'text': 'seconda', 'backgroundImage': 'bg.png', 'isTextWhite': true},
        ],
        'type': 'answer',
        'created_at': '2026-01-01T11:00:00Z',
        'user_id': 'user-2',
        'conversation_id': 'conversation-1',
      },
    ]);

    final result = await ConversationService.fetchConversation(
      'conversation-1',
    );

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

    final result = await ConversationService.fetchConversation(
      'conversation-1',
    );

    expect(result.single.hinoo!.type.name, 'answer');
  });

  test(
    'preferisce una sola copia Honoo salvata dalla Luna alla radice',
    () async {
      final honoo = harness.stubTable('honoo');
      final hinoo = harness.stubTable('hinoo');
      honoo.queueResponse(<Map<String, dynamic>>[
        {
          'id': 'moon-root',
          'text': 'stesso contenuto',
          'image_url': 'image.png',
          'destination': 'moon',
          'created_at': '2026-01-01T09:00:00Z',
          'updated_at': '2026-01-01T09:00:00Z',
          'user_id': 'author',
          'conversation_id': 'conversation-1',
          'is_from_moon_saved': false,
        },
        {
          'id': 'saved-root',
          'text': 'stesso contenuto',
          'image_url': 'image.png',
          'destination': 'chest',
          'created_at': '2026-01-01T10:00:00Z',
          'updated_at': '2026-01-01T10:00:00Z',
          'user_id': 'test_user',
          'conversation_id': 'conversation-1',
          'is_from_moon_saved': true,
        },
        {
          'id': 'reply',
          'text': 'risposta',
          'image_url': '',
          'destination': 'reply',
          'reply_to': 'moon-root',
          'created_at': '2026-01-01T11:00:00Z',
          'updated_at': '2026-01-01T11:00:00Z',
          'user_id': 'test_user',
          'conversation_id': 'conversation-1',
          'is_from_moon_saved': false,
        },
      ]);
      hinoo.queueResponse(<Map<String, dynamic>>[]);

      final result = await ConversationService.fetchConversation(
        'conversation-1',
      );

      expect(result.map((entry) => entry.id), ['saved-root', 'reply']);
      expect(result.first.isFromMoonSaved, isTrue);
    },
  );

  test(
    'preferisce una sola copia Hinoo salvata dalla Luna alla radice',
    () async {
      final honoo = harness.stubTable('honoo');
      final hinoo = harness.stubTable('hinoo');
      honoo.queueResponse(<Map<String, dynamic>>[]);
      final pages = <Map<String, dynamic>>[
        {
          'text': 'stesso contenuto',
          'backgroundImage': 'bg.png',
          'isTextWhite': true,
        },
      ];
      hinoo.queueResponse(<Map<String, dynamic>>[
        {
          'id': 'moon-root',
          'pages': pages,
          'type': 'moon',
          'created_at': '2026-01-01T09:00:00Z',
          'user_id': 'author',
          'conversation_id': 'conversation-1',
          'is_from_moon_saved': false,
        },
        {
          'id': 'saved-root',
          'pages': pages,
          'type': 'personal',
          'created_at': '2026-01-01T10:00:00Z',
          'user_id': 'test_user',
          'conversation_id': 'conversation-1',
          'is_from_moon_saved': true,
        },
        {
          'id': 'reply',
          'pages': <Map<String, dynamic>>[
            {
              'text': 'risposta',
              'backgroundImage': 'reply.png',
              'isTextWhite': true,
            },
          ],
          'type': 'answer',
          'reply_to': 'moon-root',
          'created_at': '2026-01-01T11:00:00Z',
          'user_id': 'test_user',
          'conversation_id': 'conversation-1',
          'is_from_moon_saved': false,
        },
      ]);

      final result = await ConversationService.fetchConversation(
        'conversation-1',
      );

      expect(result.map((entry) => entry.id), ['saved-root', 'reply']);
      expect(result.first.isFromMoonSaved, isTrue);
    },
  );

  test('ricostruisce il segnaposto per una conversazione orfana', () async {
    final honoo = harness.stubTable('honoo');
    final hinoo = harness.stubTable('hinoo');
    final tombstones = harness.stubTable('conversation_tombstones');
    honoo.queueResponse(<Map<String, dynamic>>[
      {
        'id': 'reply-1',
        'text': 'risposta',
        'image_url': '',
        'destination': 'reply',
        'reply_to': 'deleted-root',
        'created_at': '2026-01-01T11:00:00Z',
        'updated_at': '2026-01-01T11:00:00Z',
        'user_id': 'test_user',
        'conversation_id': 'conversation-1',
      },
    ]);
    hinoo.queueResponse(<Map<String, dynamic>>[]);
    tombstones.queueResponse(<Map<String, dynamic>>[
      {
        'content_id': 'deleted-root',
        'conversation_id': 'conversation-1',
        'original_created_at': '2026-01-01T10:59:59Z',
      },
    ]);

    final result = await ConversationService.fetchConversation(
      'conversation-1',
    );

    expect(result.map((entry) => entry.id), ['deleted-root', 'reply-1']);
    expect(result.first.kind, ConversationEntryKind.deleted);
  });

  test('trasforma un contenuto soft-deleted in segnaposto', () async {
    final honoo = harness.stubTable('honoo');
    final hinoo = harness.stubTable('hinoo');
    honoo.queueResponse(<Map<String, dynamic>>[
      {
        'id': 'deleted-root',
        'created_at': '2026-01-01T10:00:00Z',
        'conversation_id': 'conversation-1',
        'admin_deleted_at': '2026-01-02T10:00:00Z',
      },
    ]);
    hinoo.queueResponse(<Map<String, dynamic>>[]);

    final result = await ConversationService.fetchConversation(
      'conversation-1',
    );

    expect(result.single.kind, ConversationEntryKind.deleted);
    expect(result.single.id, 'deleted-root');
  });

  test('include la radice quando una risposta avvia un nuovo filo', () async {
    final honoo = harness.stubTable('honoo');
    final hinoo = harness.stubTable('hinoo');
    honoo.queueResponse(<Map<String, dynamic>>[
      {
        'id': 'reply-1',
        'text': 'nuova conversazione',
        'image_url': '',
        'destination': 'reply',
        'reply_to': 'moon-root',
        'created_at': '2026-01-01T11:00:00Z',
        'updated_at': '2026-01-01T11:00:00Z',
        'user_id': 'test_user',
        'conversation_id': 'forked-conversation',
      },
    ]);
    hinoo.queueResponse(<Map<String, dynamic>>[]);
    honoo.queueResponse(<Map<String, dynamic>>[
      {
        'id': 'moon-root',
        'text': 'radice',
        'image_url': 'root.png',
        'destination': 'moon',
        'created_at': '2026-01-01T10:00:00Z',
        'updated_at': '2026-01-01T10:00:00Z',
        'user_id': 'author',
        'conversation_id': 'original-conversation',
      },
    ]);

    final result = await ConversationService.fetchConversation(
      'forked-conversation',
    );

    expect(result.map((entry) => entry.id), ['moon-root', 'reply-1']);
  });
}
