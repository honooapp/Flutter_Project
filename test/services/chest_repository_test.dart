import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Services/chest_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../test_supabase_helper.dart';

void main() {
  setUpAll(registerSupabaseFallbacks);

  late SupabaseTestHarness harness;
  late MockQueryChain hinoo;
  late ChestRepository repository;

  setUp(() {
    harness = SupabaseTestHarness(withAuthenticatedUser: true);
    hinoo = harness.stubTable('hinoo');
    repository = ChestRepository(client: harness.client);
  });

  tearDown(resetMocktailState);

  test('fetchHinooRows mantiene filtri e ordinamento dello Scrigno', () async {
    final rows = <Map<String, dynamic>>[
      {'id': 'h-1', 'pages': <dynamic>[]},
    ];
    hinoo.queueResponse(rows);

    final result = await repository.fetchHinooRows('user-1');

    expect(result, rows);
    verify(() => hinoo.in_('type', ['personal', 'answer'])).called(1);
    verify(
      () => hinoo.or(
        'user_id.eq.user-1,and(type.eq.answer,recipient_tag.eq.user-1)',
      ),
    ).called(1);
    verify(() => hinoo.order('created_at', ascending: false)).called(1);
  });

  test(
    'fetchHinooMoonFingerprints restituisce i fingerprint pubblicati',
    () async {
      hinoo.queueResponse([
        {'fingerprint': 'fp-1'},
        {'fingerprint': null},
        {'fingerprint': 'fp-2'},
      ]);

      final result = await repository.fetchHinooMoonFingerprints('user-1');

      expect(result, {'fp-1', 'fp-2'});
      verify(() => hinoo.select('fingerprint')).called(1);
      verify(() => hinoo.eq('user_id', 'user-1')).called(1);
      verify(() => hinoo.eq('type', 'moon')).called(1);
    },
  );

  test('deleteHinoo elimina esclusivamente la riga indicata', () async {
    hinoo.queueResponse(<String, dynamic>{});

    await repository.deleteHinoo('h-1');

    verify(() => hinoo.delete()).called(1);
    verify(() => hinoo.eq('id', 'h-1')).called(1);
  });
}
