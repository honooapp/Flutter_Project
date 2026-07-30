import 'package:shared_preferences/shared_preferences.dart';

import '../env/env.dart';

typedef ComposerPreferencesLoader = Future<SharedPreferences> Function();
typedef ComposerOnboardingSuppressionCheck = bool Function();

class ComposerOnboardingService {
  ComposerOnboardingService({
    ComposerPreferencesLoader? preferencesLoader,
    ComposerOnboardingSuppressionCheck? isSuppressed,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance,
       _isSuppressed = isSuppressed ?? _defaultIsSuppressed;

  static const preferenceKey = 'composer_onboarding_dismissed_v1';

  final ComposerPreferencesLoader _preferencesLoader;
  final ComposerOnboardingSuppressionCheck _isSuppressed;

  Future<bool> shouldShow() async {
    if (_isSuppressed()) return false;
    final preferences = await _preferencesLoader();
    return !(preferences.getBool(preferenceKey) ?? false);
  }

  Future<void> dismissPermanently() async {
    final preferences = await _preferencesLoader();
    await preferences.setBool(preferenceKey, true);
  }

  static bool _defaultIsSuppressed() =>
      const bool.fromEnvironment('CI', defaultValue: false) ||
      readEnv('CI') == 'true' ||
      readEnv('FLUTTER_TEST') == 'true';
}
