import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Supabase + Postgrest API (v1.x)
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postgrest/postgrest.dart';

import 'package:honoo/Services/HonooService.dart';
import 'package:honoo/Entities/Honoo.dart';

/// Unico mock che implementa TUTTE le interfacce di builder usate nella catena:
/// - client.from('honoo') -> SupabaseQueryBuilder
/// - .select()/.delete()  -> PostgrestFilterBuilder
/// - .eq()/.order()       -> PostgrestFilterBuilder/PostgrestTransformBuilder
///
/// NB: PostgrestFilterBuilder / TransformBuilder sono "awaitable" (Future),
/// quindi questo mock deve anche gestire Future.then(...) per restituire valori.
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
    // Mocktail richiede fallback per alcuni tipi generici usati in any()
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    client = _MockSupabaseClient();
    chain = _MockQueryChain();

    // Usa il client mock nel service
    HonooService.$setTestClient(client);

    // client.from('honoo') -> il "chain" mock
    when(() => client.from('honoo')).thenReturn(chain);

    // Di default, i metodi di chaining ritornano SEMPRE "chain" stesso,
    // in modo da poter comporre select().eq()... ecc.
    when(() => chain.select(any())).thenReturn(chain);
    when(() => chain.delete()).thenReturn(chain);
    when(() => chain.eq(any(), any())).thenReturn(chain);
    when(() => chain.order(any(), ascending: any(named: 'ascending')))
        .thenReturn(chain);
  });

  tearDown(() {
    // Ripristina il client reale dopo ogni test
    HonooService.$setTestClient(null);
  });

  test('fetchPublicHonoo: filtra destination=moon e ordina per created_at desc', () async {
    // Dato atteso dal "await" dell'ultima chiamata (la catena è awaitable):
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

    // Qui "insegniamo" al mock cosa restituire quando viene atteso (await chain)
    // stubbando Future.then(...) sul builder finale della catena.
    when(() => chain.then<dynamic>(any(),
        onError: any(named: 'onError'))).thenAnswer((invocation) {
      final onValue = invocation.positionalArguments[0] as dynamic Function(dynamic);
      // Simula il completamento del Future con "rows"
      return Future.value(onValue(rows));
    });

    final list = await HonooService.fetchPublicHonoo();

    expect(list, isA<List<Honoo>>());
    expect(list.length, 2);
    expect(list.first.id, 2);

    // Verifiche puntuali sulla catena usata:
    verify(() => client.from('honoo')).called(1);
    verify(() => chain.select('*')).called(1);
    verify(() => chain.eq('destination', 'moon')).called(1);
    verify(() => chain.order('created_at', ascending: false)).called(1);
  });

  test('deleteHonooById: chiama delete().eq("id", id) e completa', () async {
    // Quando il builder finale viene atteso (await), completiamo con {} (o null)
    when(() => chain.then<dynamic>(any(),
        onError: any(named: 'onError'))).thenAnswer((invocation) {
      final onValue = invocation.positionalArguments[0] as dynamic Function(dynamic);
      return Future.value(onValue({}));
    });

    await HonooService.deleteHonooById('123');

    verify(() => client.from('honoo')).called(1);
    verify(() => chain.delete()).called(1);
    verify(() => chain.eq('id', '123')).called(1);
  });
}
