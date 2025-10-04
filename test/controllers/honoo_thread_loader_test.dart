// test/controllers/honoo_thread_loader_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:honoo/Controller/HonooThreadLoader.dart';
import 'package:honoo/Controller/HonooController.dart';
import 'package:honoo/Entities/Honoo.dart';

class _MockHonooController extends Mock implements HonooController {}

void main() {
  setUpAll(() {
    // Nessun fallback necessario: usiamo solo getHonooHistory
  });

  test('load(): emette loading poi success con il thread previsto', () async {
    final mock = _MockHonooController();

    // root Honoo (con dbId null: non ci interessa qui)
    final root = Honoo(
      1,
      '“radice”',
      '',
      '2024-01-01T00:00:00Z',
      '2024-01-01T00:00:00Z',
      'u1',
      HonooType.personal,
    );

    final reply = Honoo(
      2,
      '“risposta”',
      '',
      '2024-01-02T00:00:00Z',
      '2024-01-02T00:00:00Z',
      'u2',
      HonooType.answer,
      'root_uuid',
      'ventoBlu',
    );

    when(() => mock.getHonooHistory(root)).thenAnswer((_) async => [root, reply]);

    final loader = HonooThreadLoader(controller: mock);
    expect(loader.value.isLoading, isTrue); // stato iniziale del ValueNotifier

    await loader.load(root);

    expect(loader.value.isLoading, isFalse);
    expect(loader.value.thread.length, 2);
    expect(loader.value.thread.first.text, '“radice”');
    expect(loader.value.thread.last.text, '“risposta”');

    verify(() => mock.getHonooHistory(root)).called(1);
  });
}
