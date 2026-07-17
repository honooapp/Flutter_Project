import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Controller/campanelli_controller.dart';
import 'package:honoo/Services/campanelli_repository.dart';
import 'package:honoo/Services/campanelli_realtime_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockCampanelliRepository extends Mock
    implements CampanelliDataRepository {}

class _FakeSubscription implements CampanelliRealtimeSubscription {
  bool closed = false;

  @override
  void close() => closed = true;
}

class _FakeRealtimeGateway implements CampanelliRealtimeGateway {
  final ownerSubscription = _FakeSubscription();
  final visitorSubscription = _FakeSubscription();
  void Function(Map<String, dynamic>)? onPendingInsert;
  void Function(String)? onDelete;
  void Function(String)? onAccessGranted;

  @override
  CampanelliRealtimeSubscription subscribeOwner({
    required String userId,
    required List<String> ownedHinooIds,
    required void Function(Map<String, dynamic> row) onPendingInsert,
    required void Function(String id) onDelete,
  }) {
    this.onPendingInsert = onPendingInsert;
    this.onDelete = onDelete;
    return ownerSubscription;
  }

  @override
  CampanelliRealtimeSubscription subscribeVisitor({
    required String userId,
    required void Function(String targetTag) onAccessGranted,
  }) {
    this.onAccessGranted = onAccessGranted;
    return visitorSubscription;
  }
}

void main() {
  late _MockCampanelliRepository repository;
  late CampanelliController controller;

  setUp(() {
    repository = _MockCampanelliRepository();
    controller = CampanelliController(repository: repository);
  });

  tearDown(() => controller.dispose());

  test('carica righe e identifica gli Hinoo posseduti', () async {
    when(repository.fetchHouseRows).thenAnswer((_) async => [
          {
            'campanello_hinoo_id': 'hinoo-owned',
            'owner_id': 'user-1',
            'house_image_url': 'house.png',
            'bg_transform': [1, 0, 0, 1],
          },
          {
            'campanello_hinoo_id': 'hinoo-other',
            'owner_id': 'user-2',
          },
        ]);
    when(() => repository.fetchShareSettingsRows(any()))
        .thenAnswer((_) async => const [
              {'campanello_hinoo_id': 'hinoo-owned'}
            ]);
    when(() => repository.fetchHinooRows(any())).thenAnswer((_) async => const [
          {
            'id': 'hinoo-owned',
            'pages': [
              {
                'text': ' Il mio campanello ',
                'backgroundImage': 'bell.png',
                'isTextWhite': true,
                'bgScale': 1.2,
                'bgOffsetX': 0.1,
                'bgOffsetY': -0.2,
              }
            ],
          }
        ]);

    final loadingStates = <bool>[];
    controller.addListener(
      () => loadingStates.add(controller.state.isLoading),
    );
    final state = await controller.load('user-1');

    expect(loadingStates, [true, false]);
    expect(state.error, isNull);
    expect(state.ownedHinooIds, ['hinoo-owned']);
    expect(state.entries, hasLength(1));
    expect(state.entries.single.text, 'Il mio campanello');
    expect(state.entries.single.ownerId, 'user-1');
    expect(state.entries.single.houseImageUrl, 'house.png');
    expect(state.entries.single.bgTransform, [1.0, 0.0, 0.0, 1.0]);
    verify(() => repository.fetchShareSettingsRows(
          ['hinoo-owned', 'hinoo-other'],
        )).called(1);
  });

  test('pubblica uno stato di errore senza conservare dati parziali', () async {
    when(repository.fetchHouseRows).thenThrow(StateError('offline'));

    final state = await controller.load('user-1');

    expect(state.isLoading, isFalse);
    expect(state.error, isA<StateError>());
    expect(state.entries, isEmpty);
  });

  test('con nessuna casa evita le query successive', () async {
    when(repository.fetchHouseRows).thenAnswer((_) async => const []);
    when(() => repository.fetchShareSettingsRows(any()))
        .thenAnswer((_) async => const []);
    when(() => repository.fetchHinooRows(any()))
        .thenAnswer((_) async => const []);

    await controller.load('user-1');

    verify(() => repository.fetchShareSettingsRows(const [])).called(1);
    verify(() => repository.fetchHinooRows(const [])).called(1);
  });

  test('carica e mappa le bussate pendenti', () async {
    when(() => repository.fetchPendingKnockRows(['hinoo-1']))
        .thenAnswer((_) async => const [
              {
                'id': 'knock-1',
                'target_house_tag': 'hinoo-1',
                'created_at': '2026-07-17T10:00:00Z',
                'honoo_id': 'honoo-1',
              },
              {'id': '', 'target_house_tag': 'invalid'},
            ]);

    final knocks = await controller.loadPendingKnocks(['hinoo-1']);

    expect(knocks, hasLength(1));
    expect(knocks.single.id, 'knock-1');
    expect(knocks.single.createdAt, DateTime.parse('2026-07-17T10:00:00Z'));
    expect(controller.pendingKnockTags, {'hinoo-1'});
  });

  test('Realtime sostituisce duplicati e rimuove per id', () {
    expect(
      controller.addPendingKnockRow(const {
        'id': 'knock-1',
        'target_house_tag': 'hinoo-1',
        'created_at': '2026-07-17T10:00:00Z',
      }),
      isTrue,
    );
    controller.addPendingKnockRow(const {
      'id': 'knock-1',
      'target_house_tag': 'hinoo-2',
      'created_at': '2026-07-17T11:00:00Z',
    });

    expect(controller.state.pendingKnocks, hasLength(1));
    expect(controller.state.pendingKnocks.single.targetTag, 'hinoo-2');

    controller.removePendingKnock('knock-1');
    expect(controller.state.pendingKnocks, isEmpty);
    expect(controller.pendingKnockTags, isEmpty);
  });

  test('inoltra eventi Realtime e chiude le sottoscrizioni', () {
    final realtime = _FakeRealtimeGateway();
    final realtimeController = CampanelliController(
      repository: repository,
      realtimeGateway: realtime,
    );
    var insertEvents = 0;
    var deleteEvents = 0;
    String? grantedTag;

    realtimeController.startOwnerRealtime(
      userId: 'user-1',
      ownedHinooIds: const ['hinoo-1'],
      onPendingKnock: (_) => insertEvents++,
      onPendingRemoved: () => deleteEvents++,
    );
    realtimeController.startVisitorRealtime(
      userId: 'user-1',
      onAccessGranted: (tag) => grantedTag = tag,
    );
    realtime.onPendingInsert!(const {
      'id': 'knock-1',
      'target_house_tag': 'hinoo-1',
      'created_at': '2026-07-17T12:00:00Z',
    });
    realtime.onDelete!('knock-1');
    realtime.onAccessGranted!('hinoo-1');

    expect(insertEvents, 1);
    expect(deleteEvents, 1);
    expect(grantedTag, 'hinoo-1');
    expect(realtimeController.state.pendingKnocks, isEmpty);

    realtimeController.dispose();
    expect(realtime.ownerSubscription.closed, isTrue);
    expect(realtime.visitorSubscription.closed, isTrue);
  });

  test('impedisce refresh periodici concorrenti', () async {
    final response = Completer<List<dynamic>>();
    when(() => repository.fetchPendingKnockRows(['hinoo-1']))
        .thenAnswer((_) => response.future);
    var changes = 0;

    final first = controller.refreshPendingKnocks(
      ['hinoo-1'],
      onChanged: () => changes++,
    );
    final second = await controller.refreshPendingKnocks(
      ['hinoo-1'],
      onChanged: () => changes++,
    );
    response.complete(const []);

    expect(second, isFalse);
    expect(await first, isTrue);
    expect(changes, 1);
    verify(() => repository.fetchPendingKnockRows(['hinoo-1'])).called(1);
  });

  test('timer periodico viene fermato dal controller', () async {
    when(() => repository.fetchPendingKnockRows(['hinoo-1']))
        .thenAnswer((_) async => const []);
    var changes = 0;

    await controller.startPendingKnockRefresh(
      ownedHinooIds: ['hinoo-1'],
      onChanged: () => changes++,
      interval: const Duration(milliseconds: 20),
    );
    await Future<void>.delayed(const Duration(milliseconds: 55));
    controller.stopPendingKnockRefresh();
    final stoppedAt = changes;
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(stoppedAt, greaterThanOrEqualTo(2));
    expect(changes, stoppedAt);
  });
}
