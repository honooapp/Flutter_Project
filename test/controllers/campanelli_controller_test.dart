import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Controller/campanelli_controller.dart';
import 'package:honoo/Services/campanelli_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockCampanelliRepository extends Mock
    implements CampanelliDataRepository {}

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
}
