import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:honoo/Services/hinoo_service.dart';
import 'package:honoo/Entities/hinoo.dart';

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

    HinooService.$setTestClient(client);
    when(() => client.from(any())).thenAnswer((_) => chain);

    when(() => chain.select(any())).thenAnswer((_) => chain);
    when(() => chain.eq(any(), any())).thenAnswer((_) => chain);
    when(() => chain.order(any(), ascending: any(named: 'ascending')))
        .thenAnswer((_) => chain);
    when(() => chain.limit(any())).thenAnswer((_) => chain);

    when(() => chain.maybeSingle()).thenAnswer((_) => chain);
  });

  tearDown(() {
    HinooService.$setTestClient(null);
    resetMocktailState();
  });

  test('fetchUserHinoo: type=personal → mapping corretto e ordine DESC',
      () async {
    final rows = [
      {
        'pages': [
          {
            'text': 'ciao',
            'backgroundImage': null,
            'isTextWhite': true,
            'bgScale': 1.0,
            'bgOffsetX': 0.0,
            'bgOffsetY': 0.0,
          }
        ],
        'type': 'personal',
        'recipient_tag': null,
        'created_at': '2024-01-02T00:00:00Z',
      },
      {
        'pages': [
          {
            'text': 'altro',
            'backgroundImage': 'https://img',
            'isTextWhite': false,
            'bgScale': 0.8,
            'bgOffsetX': 5.0,
            'bgOffsetY': -2.0,
          }
        ],
        'type': 'personal',
        'recipient_tag': 'ventoBlu',
        'created_at': '2024-01-01T00:00:00Z',
      }
    ];
    chain.queueResponse(rows);

    final list =
        await HinooService.fetchUserHinoo('u1', type: HinooType.personal);

    expect(list, isA<List<HinooDraft>>());
    expect(list.length, 2);
    expect(list.first.type, HinooType.personal);
    expect(list.first.pages.first.text, 'ciao');

    verify(() => client.from('hinoo')).called(1);
    verify(() => chain.select('pages,type,recipient_tag,created_at')).called(1);
    verify(() => chain.eq('user_id', 'u1')).called(1);
    verify(() => chain.eq('type', 'personal')).called(1);
    verify(() => chain.order('created_at', ascending: false)).called(1);
  });

  test('fetchUserHinoo: type=moon → filtra "moon" e ordina DESC', () async {
    final rows = [
      {
        'pages': [
          {'text': 'luna'}
        ],
        'type': 'moon',
        'recipient_tag': null,
        'created_at': '2024-01-03T00:00:00Z',
      }
    ];
    chain.queueResponse(rows);

    final list = await HinooService.fetchUserHinoo('u2', type: HinooType.moon);

    expect(list.length, 1);
    expect(list.first.type, HinooType.moon);
    expect(list.first.pages.first.text, 'luna');

    verify(() => client.from('hinoo')).called(1);
    verify(() => chain.eq('user_id', 'u2')).called(1);
    verify(() => chain.eq('type', 'moon')).called(1);
    verify(() => chain.order('created_at', ascending: false)).called(1);
  });
}
