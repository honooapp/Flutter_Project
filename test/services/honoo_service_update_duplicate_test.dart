import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postgrest/postgrest.dart';

import 'package:honoo/Services/HinooService.dart';
import 'package:honoo/Entities/Hinoo.dart';

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
    if (invocation.memberName == #then && invocation.positionalArguments.isNotEmpty) {
      final onValue = invocation.positionalArguments[0] as dynamic Function(dynamic);
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
    HinooDraft _sampleDraft() => const HinooDraft(
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

    test('se ESISTE già un duplicato → ritorna false e NON inserisce', () async {
      chain.queueResponse([
        {'id': 99}
      ]);

      final res = await HinooService.duplicateToMoon(_sampleDraft());

      expect(res, isFalse);
      verify(() => client.from('hinoo')).called(1);
      verify(() => chain.select('id')).called(1);
      verify(() => chain.eq('user_id', 'u-1')).called(1);
      verify(() => chain.eq('type', 'moon')).called(1);
      verify(() => chain.eq('fingerprint', any<String>())).called(1);
      verify(() => chain.limit(1)).called(1);
      verifyNever(() => chain.insert(any()));
    });

    test('se NON esiste duplicato → fa insert e ritorna true', () async {
      chain.queueResponse(<Map<String, dynamic>>[]);
      chain.queueResponse(<String, dynamic>{});

      final res = await HinooService.duplicateToMoon(_sampleDraft());

      expect(res, isTrue);
      verify(() => client.from('hinoo')).called(greaterThanOrEqualTo(1));
      verify(() => chain.select('id')).called(1);
      verify(() => chain.eq('user_id', 'u-1')).called(1);
      verify(() => chain.eq('type', 'moon')).called(1);
      verify(() => chain.eq('fingerprint', any<String>())).called(1);
      verify(() => chain.limit(1)).called(1);
      verify(() => chain.insert(any())).called(1);
    });
  });
}
