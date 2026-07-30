import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Services/composer_onboarding_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('continua a mostrare il suggerimento finché non viene chiuso', () async {
    final service = ComposerOnboardingService(isSuppressed: () => false);

    expect(await service.shouldShow(), isTrue);
    expect(await service.shouldShow(), isTrue);
  });

  test('non mostra più il suggerimento dopo la chiusura permanente', () async {
    final service = ComposerOnboardingService(isSuppressed: () => false);

    await service.dismissPermanently();

    expect(await service.shouldShow(), isFalse);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool(ComposerOnboardingService.preferenceKey),
      isTrue,
    );
  });

  test('non mostra il suggerimento quando è soppresso', () async {
    final service = ComposerOnboardingService(isSuppressed: () => true);

    expect(await service.shouldShow(), isFalse);
  });
}
