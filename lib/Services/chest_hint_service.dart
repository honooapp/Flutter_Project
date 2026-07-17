import 'package:shared_preferences/shared_preferences.dart';

import '../env/env.dart';

typedef ChestPreferencesLoader = Future<SharedPreferences> Function();
typedef ChestHintSuppressionCheck = bool Function();

class ChestHintService {
  ChestHintService({
    ChestPreferencesLoader? preferencesLoader,
    ChestHintSuppressionCheck? isSuppressed,
  })  : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance,
        _isSuppressed = isSuppressed ?? _defaultIsSuppressed;

  static const preferenceKey = 'scrigno_info_seen_v1';

  final ChestPreferencesLoader _preferencesLoader;
  final ChestHintSuppressionCheck _isSuppressed;

  Future<bool> shouldShow() async {
    if (_isSuppressed()) return false;
    final preferences = await _preferencesLoader();
    if (preferences.getBool(preferenceKey) ?? false) return false;
    await preferences.setBool(preferenceKey, true);
    return true;
  }

  static bool _defaultIsSuppressed() =>
      const bool.fromEnvironment('CI', defaultValue: false) ||
      readEnv('CI') == 'true' ||
      readEnv('FLUTTER_TEST') == 'true';
}
