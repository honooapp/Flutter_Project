import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:honoo/Services/hinoo_service.dart';
import 'package:honoo/Services/duplication_result.dart';
import 'package:honoo/Entities/hinoo.dart';

class _MockClient extends Mock implements SupabaseClient {}

class _MockAuth extends Mock implements GoTrueClient {}

class _MockUser extends Mock implements User {}

class _QueuedError {
  const _QueuedError(this.error);

  final Object error;
}

class _MockQueryChain extends Mock
    implements
        SupabaseQueryBuilder,
        PostgrestFilterBuilder<dynamic>,
        PostgrestTransformBuilder<dynamic> {
  final Queue<dynamic> _responses = Queue<dynamic>();

  void queueResponse(dynamic value) => _responses.add(value);
  void queueError(Object error) => _responses.add(_QueuedError(error));

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #then &&
        invocation.positionalArguments.isNotEmpty) {
      final onValue =
          invocation.positionalArguments[0] as dynamic Function(dynamic);
      final result = _responses.isEmpty ? null : _responses.removeFirst();
      if (result is _QueuedError) throw result.error;
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
    when(() => user.id).thenReturn('u-1');

    when(() => client.from('hinoo')).thenAnswer((_) => chain);

    when(() => chain.select(any())).thenAnswer((_) => chain);
    when(() => chain.eq(any(), any())).thenAnswer((_) => chain);
    when(() => chain.limit(any())).thenAnswer((_) => chain);
    when(() => chain.insert(any())).thenAnswer((_) => chain);
    when(() => chain.maybeSingle()).thenAnswer((_) => chain);

    HinooService.$setTestClient(client);
  });

  tearDown(() {
    HinooService.$setTestClient(null);
    resetMocktailState();
  });

  group('HinooService.duplicateToMoon', () {
    HinooDraft sampleDraft() => const HinooDraft(
      pages: [
        HinooSlide(
          text: 'Testo',
          backgroundImage: null,
          isTextWhite: true,
          bgScale: 1.0,
          bgOffsetX: 0,
          bgOffsetY: 0,
        ),
      ],
      type: HinooType.personal,
      recipientTag: null,
    );

    test(
      'il conflitto univoco atomico viene riconosciuto come duplicato',
      () async {
        chain.queueError(
          const PostgrestException(message: 'duplicate', code: '23505'),
        );

        final res = await HinooService.duplicateToMoon(sampleDraft());

        expect(res, DuplicationResult.alreadyPresent);
        verify(() => client.from('hinoo')).called(1);
        verify(() => chain.insert(any())).called(1);
        verifyNever(() => chain.select(any()));
      },
    );

    test('due invii consecutivi creano due copie sulla Luna', () async {
      chain.queueResponse(<String, dynamic>{});
      chain.queueResponse(<String, dynamic>{});

      final first = await HinooService.duplicateToMoon(sampleDraft());
      final second = await HinooService.duplicateToMoon(sampleDraft());

      expect(first, DuplicationResult.inserted);
      expect(second, DuplicationResult.inserted);
      verify(() => client.from('hinoo')).called(2);
      verify(() => chain.insert(any())).called(2);
      verifyNever(() => chain.select(any()));
    });

    test('rifiuta un hinoo salvato dalla Luna', () async {
      await expectLater(
        HinooService.duplicateToMoon(
          sampleDraft().copyWith(isFromMoonSaved: true),
        ),
        throwsArgumentError,
      );
      verifyNever(() => client.from('hinoo'));
    });
  });
}
