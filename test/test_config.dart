import 'dart:async';
import 'dart:ui';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Impostazioni globali per golden tests a densità fissa
  // (utile per stabilizzare i render su CI).
  PlatformDispatcher.instance.onBeginFrame = (_) {};
  await testMain();
}
