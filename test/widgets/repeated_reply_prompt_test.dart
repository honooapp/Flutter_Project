import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Services/reply_conversation_service.dart';
import 'package:honoo/Widgets/repeated_reply_prompt.dart';
import 'package:mocktail/mocktail.dart';

import '../test_supabase_helper.dart';

void main() {
  setUpAll(registerSupabaseFallbacks);

  late SupabaseTestHarness harness;
  late ReplyConversationService service;

  setUp(() {
    harness = SupabaseTestHarness(withAuthenticatedUser: true)
      ..enableOverrides();
    service = ReplyConversationService(
      client: harness.client,
      lookup: (_) async => 'conversation-1',
    );
  });

  tearDown(() {
    harness.disableOverrides();
    resetMocktailState();
  });

  testWidgets('No aggiunge la risposta alla conversazione precedente', (
    tester,
  ) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await chooseReplyConversation(
                context: context,
                parentId: 'root-1',
                defaultConversationId: 'default-conversation',
                contentName: 'honoo',
                service: service,
              );
            },
            child: const Text('Rispondi'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Rispondi'));
    await tester.pumpAndSettle();

    expect(find.text('Hai già risposto a questo honoo'), findsOneWidget);
    expect(
      find.text('Vuoi che questa risposta crei una nuova conversazione?'),
      findsOneWidget,
    );
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();

    expect(result, 'conversation-1');
  });

  testWidgets('Sì crea una conversazione distinta per un hinoo', (
    tester,
  ) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await chooseReplyConversation(
                context: context,
                parentId: 'root-1',
                defaultConversationId: 'default-conversation',
                contentName: 'hinoo',
                service: service,
              );
            },
            child: const Text('Rispondi'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Rispondi'));
    await tester.pumpAndSettle();

    expect(find.text('Hai già risposto a questo hinoo'), findsOneWidget);
    await tester.tap(find.text('Sì'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result, isNot('conversation-1'));
    expect(result, isNot('default-conversation'));
  });
}
