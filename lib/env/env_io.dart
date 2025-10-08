/*
Contesto: su desktop, mobile e test abbiamo accesso a `dart:io`, quindi possiamo leggere le variabili d'ambiente anche quando non sono passate via `--dart-define`.
Questo loader tenta prima le define compilazione per allinearsi al Web, poi ricade su `Platform.environment`.
*/

import 'dart:io';

/// IO (desktop/mobile/test): prima prova --dart-define, poi Platform.environment.
/// Esempio di uso:
///   final url = readEnv('SUPABASE_URL');
String readEnv(String key, {String fallback = ''}) {
  final v = String.fromEnvironment(key, defaultValue: '');
  if (v.isNotEmpty) return v;
  return Platform.environment[key] ?? fallback;
}
