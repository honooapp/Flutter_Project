import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Services/campanelli_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../test_supabase_helper.dart';

void main() {
  setUpAll(registerSupabaseFallbacks);

  late SupabaseTestHarness harness;
  late MockQueryChain houses;
  late MockQueryChain settings;
  late MockQueryChain hinoo;
  late MockQueryChain honoo;
  late MockQueryChain houseAccess;
  late CampanelliDataRepository repository;

  setUp(() {
    harness = SupabaseTestHarness(withAuthenticatedUser: true);
    houses = harness.stubTable('case');
    settings = harness.stubTable('house_share_settings');
    hinoo = harness.stubTable('hinoo');
    honoo = harness.stubTable('honoo');
    houseAccess = harness.stubTable('house_access');
    repository = CampanelliDataRepository(client: harness.client);
  });

  tearDown(resetMocktailState);

  test('fetchHouseRows mantiene colonne e tabella originali', () async {
    final rows = <Map<String, dynamic>>[
      {'campanello_hinoo_id': 'h-1', 'owner_id': 'user-1'}
    ];
    houses.queueResponse(rows);

    expect(await repository.fetchHouseRows(), rows);
    verify(() => harness.client.from('case')).called(1);
    verify(() => houses.select(
          'campanello_hinoo_id,owner_id,house_image_url,bg_transform',
        )).called(1);
  });

  test('fetchShareSettingsRows mantiene filtro sugli Hinoo', () async {
    final rows = <Map<String, dynamic>>[
      {'campanello_hinoo_id': 'h-1', 'share_mode': 'honoo'}
    ];
    settings.queueResponse(rows);

    expect(await repository.fetchShareSettingsRows(['h-1', 'h-2']), rows);
    verify(() => harness.client.from('house_share_settings')).called(1);
    verify(() => settings.in_(
          'campanello_hinoo_id',
          ['h-1', 'h-2'],
        )).called(1);
  });

  test('fetchHinooRows mantiene filtro sugli identificativi', () async {
    final rows = <Map<String, dynamic>>[
      {'id': 'h-1', 'pages': <dynamic>[]}
    ];
    hinoo.queueResponse(rows);

    expect(await repository.fetchHinooRows(['h-1']), rows);
    verify(() => harness.client.from('hinoo')).called(1);
    verify(() => hinoo.select('id,pages')).called(1);
    verify(() => hinoo.in_('id', ['h-1'])).called(1);
  });

  test('liste vuote evitano query settings e Hinoo', () async {
    expect(await repository.fetchShareSettingsRows(const []), isEmpty);
    expect(await repository.fetchHinooRows(const []), isEmpty);
    verifyNever(() => harness.client.from('house_share_settings'));
    verifyNever(() => harness.client.from('hinoo'));
  });

  test('fetchPendingKnockRows filtra case possedute e accessi non concessi',
      () async {
    final rows = <Map<String, dynamic>>[
      {'id': 'knock-1', 'target_house_tag': 'h-1'}
    ];
    houseAccess.queueResponse(rows);

    expect(await repository.fetchPendingKnockRows(['h-1']), rows);
    verify(() => houseAccess.in_('target_house_tag', ['h-1'])).called(1);
    verify(() => houseAccess.is_('granted_at', null)).called(1);
  });

  test('fetchHinooForKnock mantiene selezione e identificativo', () async {
    final row = <String, dynamic>{
      'pages': <dynamic>[],
      'type': 'answer',
    };
    hinoo.queueResponse(row);

    expect(await repository.fetchHinooForKnock('h-1'), row);
    verify(() => hinoo.select('pages,type,recipient_tag,created_at')).called(1);
    verify(() => hinoo.eq('id', 'h-1')).called(1);
    verify(() => hinoo.maybeSingle()).called(1);
  });

  test('fetchHonooForKnock mantiene selezione e identificativo', () async {
    final row = <String, dynamic>{'id': 'honoo-1', 'text': 'Test'};
    honoo.queueResponse(row);

    expect(await repository.fetchHonooForKnock('honoo-1'), row);
    verify(() => honoo.eq('id', 'honoo-1')).called(1);
    verify(() => honoo.maybeSingle()).called(1);
  });

  test('grantHouseAccess aggiorna solo la bussata indicata', () async {
    final grantedAt = DateTime.utc(2026, 7, 17, 10, 30);
    houseAccess.queueResponse(<String, dynamic>{});

    await repository.grantHouseAccess(
      knockId: 'knock-1',
      grantedAt: grantedAt,
    );

    verify(() => houseAccess.update({
          'granted_at': '2026-07-17T10:30:00.000Z',
        })).called(1);
    verify(() => houseAccess.eq('id', 'knock-1')).called(1);
  });
}
