import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Supabase + Postgrest API (v1.x)
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postgrest/postgrest.dart';

import 'package:honoo/Services/HonooService.dart';
import 'package:honoo/Entities/Honoo.dart';

/// Mock unico che implementa i builder usati nella catena:
/// - client.from('honoo') -> SupabaseQueryBuilder
/// - .select/.delete/.eq/.order -> Postgrest* builders
/// I builder Postgrest sono "awaitable", quindi mockiamo anche Future.then(...)
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
    // Fallback per any() su mappe/argomenti dinamici
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    client = _MockSupabaseClient();
    chain  = _MockQueryChain();

    // Inietta il client mock nel service
    HonooService.$setTestClient(client);

    // client.from('honoo') -> chain
    when(() => client.from('honoo')).thenReturn(chain);

    // Chaining fluente: ogni step ritorna la stessa chain
    when(() => chain.select(any())).thenReturn(chain);
    when(() => chain.delete()).thenReturn(chain);
    when(() => chain.eq(any(), any())).thenReturn(chain);
    when(() => chain.order(any(), ascending: any(named: 'ascending')))
        .thenReturn(chain);
  });

  tearDown(() {
    HonooService.$setTestClient(null);
    resetMocktailState(); // opzionale ma utile per isolamento tra test
  });

  test('fetchPublicHonoo: filtra destination=moon e ordina per created_at desc', () async {
    // Dati simulati restituiti dall'await della catena
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

    // Stubbiamo il completamento del Future finale (await chain)
    when(() => chain.then<dynamic>(any(), onError: any(named: 'onError')))
        .thenAnswer((invocation) async {
      final onValue = invocation.positionalArguments[0] as dynamic Function(dynamic);
      return onValue(rows);
    });

    final list = await HonooService.fetchPublicHonoo();

    expect(list, isA<List<Honoo>>());
    expect(list.length, 2);
    expect(list.first.id, 2);

    verify(() => client.from('honoo')).called(1);
    verify(() => chain.select('*')).called(1);
    verify(() => chain.eq('destination', 'moon')).called(1);
    verify(() => chain.order('created_at', ascending: false)).called(1);
  });

  test('deleteHonooById: chiama delete().eq("id", id) e completa', () async {
    when(() => chain.then<dynamic>(any(), onError: any(named: 'onError')))
        .thenAnswer((invocation) async {
      final onValue = invocation.positionalArguments[0] as dynamic Function(dynamic);
      return onValue(<String, dynamic>{});
    });

    await HonooService.deleteHonooById('123');

    verify(() => client.from('honoo')).called(1);
    verify(() => chain.delete()).called(1);
    verify(() => chain.eq('id', '123')).called(1);
  });
}
