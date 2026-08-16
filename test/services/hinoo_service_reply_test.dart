import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:honoo/Entities/hinoo.dart';
import 'package:honoo/Services/hinoo_service.dart';

class _MockClient extends Mock implements SupabaseClient {}

class _MockAuth extends Mock implements GoTrueClient {}

class _MockUser extends Mock implements User {}

class _MockQueryChain extends Mock
    implements
        SupabaseQueryBuilder,
        PostgrestFilterBuilder<dynamic>,
        PostgrestTransformBuilder<dynamic> {
  final Queue<dynamic> _responses = Queue<dynamic>();

  void queueResponse(dynamic value) => _responses.add(value);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #then &&
        invocation.positionalArguments.isNotEmpty) {
      final onValue =
          invocation.positionalArguments[0] as dynamic Function(dynamic);
      final result = _responses.isEmpty ? null : _responses.removeFirst();
      return Future.value(onValue(result));
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  late _MockClient client;
  late _MockAuth auth;
  late _MockUser user;
  late _MockQueryChain chain;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    client = _MockClient();
    auth = _MockAuth();
    user = _MockUser();
    chain = _MockQueryChain();

    when(() => client.auth).thenReturn(auth);
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.id).thenReturn('user-1');

    when(() => client.from('hinoo')).thenAnswer((_) => chain);
    when(() => chain.insert(any())).thenAnswer((_) => chain);
    when(() => chain.select(any())).thenAnswer((_) => chain);
    when(() => chain.maybeSingle()).thenAnswer((_) => chain);

    HinooService.$setTestClient(client);
  });

  tearDown(() {
    HinooService.$setTestClient(null);
    resetMocktailState();
  });

  test('publishHinoo: reply salva reply_to e recipient_tag', () async {
    chain.queueResponse(<String, dynamic>{'id': 'row-1'});

    const draft = HinooDraft(
      pages: [
        HinooSlide(
          text: 'Testo reply',
          backgroundImage: 'bg.png',
          isTextWhite: true,
          bgScale: 1.0,
          bgOffsetX: 0,
          bgOffsetY: 0,
        ),
      ],
      type: HinooType.answer,
      recipientTag: 'recipient-1',
      replyTo: 'root-1',
      conversationId: 'conversation-1',
    );

    await HinooService.publishHinoo(draft);

    final captured =
        verify(() => chain.insert(captureAny())).captured.single
            as Map<String, dynamic>;
    expect(captured['type'], 'answer');
    expect(captured['reply_to'], 'root-1');
    expect(captured['recipient_tag'], 'recipient-1');
    expect(captured['conversation_id'], 'conversation-1');
    expect(captured.containsKey('created_at'), isFalse);
  });

  test('publishHinoo: non salva una risposta senza reply_to', () async {
    const draft = HinooDraft(
      pages: [
        HinooSlide(
          text: 'Testo reply',
          backgroundImage: 'bg.png',
          isTextWhite: true,
        ),
      ],
      type: HinooType.answer,
      recipientTag: 'recipient-1',
      conversationId: 'conversation-1',
    );

    expect(
      () => HinooService.publishHinoo(draft),
      throwsA(isA<ArgumentError>()),
    );
    verifyNever(() => chain.insert(any()));
  });
}
