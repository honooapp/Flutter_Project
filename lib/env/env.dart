/*
Contesto: Flutter Web non supporta `dart:io`, quindi `Platform.environment` causa "Unsupported operation".
Soluzione: usa un loader condizionale che legge prima le variabili da `--dart-define` sul Web e cade su `Platform.environment` solo dove consentito (IO).
*/

// Se siamo sul Web usa env_web.dart, altrimenti env_io.dart
export 'env_web.dart' if (dart.library.io) 'env_io.dart';
