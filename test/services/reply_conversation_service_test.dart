import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Services/reply_conversation_service.dart';
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

  test('riusa l’ultima conversazione che non ha una contro-risposta', () async {
    final result = await ReplyConversationService(
      client: harness.client,
      lookup: (_) async => 'conversation-1',
    ).findPreviousUnansweredReply(parentId: 'root-1');

    expect(result?.conversationId, 'conversation-1');
  });

  test('non propone il riuso dopo una contro-risposta', () async {
    final result = await ReplyConversationService(
      client: harness.client,
      lookup: (_) async => null,
    ).findPreviousUnansweredReply(parentId: 'root-1');

    expect(result, isNull);
  });
}
