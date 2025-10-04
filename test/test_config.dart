import 'dart:async';
import 'dart:ui' as ui;

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Impostazioni globali per golden tests a densità fissa
  // (utile per stabilizzare i render su CI).
  ui.window.onBeginFrame = (_) {};
  await testMain();
}
