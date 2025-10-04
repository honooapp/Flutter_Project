import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Supabase 1.x
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postgrest/postgrest.dart';

import 'package:honoo/Services/HinooService.dart';
import 'package:honoo/Entities/Hinoo.dart';

/// Mock unico che si comporta come i builder usati da supabase 1.x:
/// - SupabaseQueryBuilder (ritorno di client.from(...))
/// - PostgrestFilterBuilder (select/eq/order/limit/maybeSingle/upsert/insert)
/// - PostgrestTransformBuilder (order/limit/maybeSingle)
class _MockQueryChain extends Mock
    implements
        SupabaseQueryBuilder,
        PostgrestFilterBuilder<dynamic>,
        PostgrestTransformBuilder<dynamic> {}

class _MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late _MockSupabaseClient client;
  late _MockQueryChain chain;

  setUpAll(() {
    // fallback per named/dynamic usati in any()
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    client = _MockSupabaseClient();
    chain  = _MockQueryChain();

    // usa il client mock nel service
    HinooService.$setTestClient(client);

    // client.from('hinoo' | 'hinoo_drafts' ...) -> chain
    when(() => client.from(any())).thenReturn(chain);

    // chaining: ogni step torna la chain
    when(() => chain.select(any())).thenReturn(chain);
    when(() => chain.eq(any(), any())).thenReturn(chain);
    when(() => chain.order(any(), ascending: any(named: 'ascending')))
        .thenReturn(chain);
    when(() => chain.limit(any())).thenReturn(chain);
    // 👇 correzione: maybeSingle deve tornare la CHAIN (non un Future)
    when(() => chain.maybeSingle()).thenReturn(chain);
  });

  tearDown(() {
    HinooService.$setTestClient(null);
  });

  test('fetchUserHinoo: type=personal → mapping corretto e ordine DESC', () async {
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

    // quando la catena viene awaitata, restituiamo "rows"
    when(() => chain.then<dynamic>(any(), onError: any(named: 'onError')))
        .thenAnswer((invocation) {
      final onValue = invocation.positionalArguments[0] as dynamic Function(dynamic);
      return Future.value(onValue(rows));
    });

    final list = await HinooService.fetchUserHinoo('u1', type: HinooType.personal);

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

    when(() => chain.then<dynamic>(any(), onError: any(named: 'onError')))
        .thenAnswer((invocation) {
      final onValue = invocation.positionalArguments[0] as dynamic Function(dynamic);
      return Future.value(onValue(rows));
    });

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
