import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Services/chest_hint_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('mostra il suggerimento al primo accesso e salva la preferenza',
      () async {
    final service = ChestHintService(isSuppressed: () => false);

    expect(await service.shouldShow(), isTrue);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool(ChestHintService.preferenceKey),
      isTrue,
    );
  });

  test('non ripete il suggerimento dopo il primo accesso', () async {
    final service = ChestHintService(isSuppressed: () => false);

    expect(await service.shouldShow(), isTrue);
    expect(await service.shouldShow(), isFalse);
  });

  test('non legge né modifica le preferenze quando è soppresso', () async {
    final service = ChestHintService(isSuppressed: () => true);

    expect(await service.shouldShow(), isFalse);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey(ChestHintService.preferenceKey), isFalse);
  });
}
