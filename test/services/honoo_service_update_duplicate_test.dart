@Tags(['unit'])
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postgrest/postgrest.dart';

import 'package:honoo/Services/HinooService.dart';
import 'package:honoo/Entities/Hinoo.dart';

class _MockClient extends Mock implements SupabaseClient {}
class _MockAuth extends Mock implements GoTrueClient {}
class _MockUser extends Mock implements User {}

/// Un unico mock che può fare sia query fluenti che trasformazioni:
class _MockQueryChain extends Mock
    implements
        SupabaseQueryBuilder,
        PostgrestFilterBuilder<dynamic>,
        PostgrestTransformBuilder<dynamic> {}

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
    // user id fittizio
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.id).thenReturn('u-1');

    // from('hinoo') -> chain
    when(() => client.from('hinoo')).thenReturn(chain);

    // chain fluent
    when(() => chain.select(any())).thenReturn(chain);
    when(() => chain.eq(any(), any())).thenReturn(chain);
    when(() => chain.limit(any())).thenReturn(chain);
    when(() => chain.insert(any())).thenReturn(chain);

    // trasformazioni che ritornano ancora la chain
    when(() => chain.maybeSingle()).thenReturn(chain);

    // Inietta il client mock nel service
    HinooService.$setTestClient(client);
  });

  tearDown(() {
    HinooService.$setTestClient(null);
    resetMocktailState();
  });

  group('HinooService.duplicateToMoon', () {
    HinooDraft _sampleDraft() => HinooDraft(
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
      type: HinooType.personal, // verrà forzato a moon nel metodo
      recipientTag: null,
    );

    test('se ESISTE già un duplicato → ritorna false e NON inserisce', () async {
      // Simula select ... eq(...).eq(...).eq(...).limit(1) che restituisce lista non vuota
      when(() => chain.then<dynamic>(any(), onError: any(named: 'onError')))
          .thenAnswer((invocation) async {
        final onValue =
        invocation.positionalArguments[0] as dynamic Function(dynamic);
        return onValue([
          {'id': 99}
        ]); // esiste un record
      });

      final res = await HinooService.duplicateToMoon(_sampleDraft());

      expect(res, isFalse);
      // Verifiche catena lookup
      verify(() => client.from('hinoo')).called(1);
      verify(() => chain.select('id')).called(1);
      verify(() => chain.eq('user_id', 'u-1')).called(1);
      verify(() => chain.eq('type', 'moon')).called(1);
      verify(() => chain.eq('fingerprint', any<String>())).called(1);
      verify(() => chain.limit(1)).called(1);
      // Nessuna insert
      verifyNever(() => chain.insert(any()));
    });

    test('se NON esiste duplicato → fa insert e ritorna true', () async {
      // Primo await (lookup) -> lista vuota
      var call = 0;
      when(() => chain.then<dynamic>(any(), onError: any(named: 'onError')))
          .thenAnswer((invocation) async {
        final onValue =
        invocation.positionalArguments[0] as dynamic Function(dynamic);
        call++;
        if (call == 1) {
          return onValue(<Map<String, dynamic>>[]); // nessun duplicato
        } else {
          // Secondo await (dopo insert) — può restituire un valore qualsiasi
          return onValue(<String, dynamic>{});
        }
      });

      final res = await HinooService.duplicateToMoon(_sampleDraft());

      expect(res, isTrue);
      // Lookup eseguito
      verify(() => client.from('hinoo')).called(greaterThanOrEqualTo(1));
      verify(() => chain.select('id')).called(1);
      verify(() => chain.eq('user_id', 'u-1')).called(1);
      verify(() => chain.eq('type', 'moon')).called(1);
      verify(() => chain.eq('fingerprint', any<String>())).called(1);
      verify(() => chain.limit(1)).called(1);
      // Insert eseguita
      verify(() => chain.insert(any())).called(1);
    });
  });
}
