import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:honoo/Services/honoo_service.dart';
import 'package:honoo/Entities/honoo.dart';

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

class _MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late _MockSupabaseClient client;
  late _MockQueryChain chain;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    client = _MockSupabaseClient();
    chain = _MockQueryChain();

    HonooService.$clearCacheForTests();
    HonooService.$setTestClient(client);
    when(() => client.from('honoo')).thenAnswer((_) => chain);

    when(() => chain.select(any())).thenAnswer((_) => chain);
    when(() => chain.delete()).thenAnswer((_) => chain);
    when(() => chain.eq(any(), any())).thenAnswer((_) => chain);
    when(() => chain.order(any(), ascending: any(named: 'ascending')))
        .thenAnswer((_) => chain);
    when(() => chain.limit(any())).thenAnswer((_) => chain);
    when(() => chain.lt(any(), any())).thenAnswer((_) => chain);
  });

  tearDown(() {
    HonooService.$clearCacheForTests();
    HonooService.$setTestClient(null);
    resetMocktailState();
  });

  test('fetchPublicHonoo: filtra destination=moon e ordina per created_at desc',
      () async {
    final rows = [
      {
        'id': 2,
        'text': '“b”',
        'image_url': '',
        'created_at': '2024-01-02T00:00:00Z',
        'updated_at': '2024-01-02T00:00:00Z',
        'user_id': 'u2',
        'type': 'personal',
      },
      {
        'id': 1,
        'text': '“a”',
        'image_url': '',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
        'user_id': 'u1',
        'type': 'personal',
      },
    ];
    chain.queueResponse(rows);

    final list = await HonooService.fetchPublicHonoo();

    expect(list, isA<List<Honoo>>());
    expect(list.length, 2);
    expect(list.first.dbId, '2');

    verify(() => client.from('honoo')).called(1);
    final captured =
        verify(() => chain.select(captureAny())).captured.single as String;
    expect(
      captured,
      'id,text,image_url,destination,reply_to,recipient_tag,created_at,updated_at,user_id,is_from_moon_saved,has_replies',
    );
    verify(() => chain.limit(HonooService.defaultPageSize)).called(1);
    verify(() => chain.eq('destination', 'moon')).called(1);
    verify(() => chain.order('created_at', ascending: false)).called(1);
  });

  test('deleteHonooById: chiama delete().eq("id", id) e completa', () async {
    chain.queueResponse(<String, dynamic>{});

    await HonooService.deleteHonooById('123');

    verify(() => client.from('honoo')).called(1);
    verify(() => chain.delete()).called(1);
    verify(() => chain.eq('id', '123')).called(1);
  });
}
