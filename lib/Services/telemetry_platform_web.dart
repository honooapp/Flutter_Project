// ignore: avoid_web_libraries_in_flutter
import 'dart:js_util' as js_util;

class TelemetryPlatform {
  static void initSentry(String dsn) {
    if (dsn.isEmpty) return;
    _safeCall('honooInitSentry', [dsn]);
  }

  static void captureException(
    Object error,
    StackTrace? stack,
    Map<String, Object?>? context,
  ) {
    final payload = {
      'error': error.toString(),
      if (stack != null) 'stack': stack.toString(),
      if (context != null && context.isNotEmpty) 'context': context,
    };
    _safeCall('honooCaptureException', [payload]);
  }

  static void addBreadcrumb(
    String category,
    String message,
    Map<String, Object?>? data,
  ) {
    _safeCall('honooAddBreadcrumb', [category, message, data ?? const {}]);
  }

  static void _safeCall(String method, List<dynamic> args) {
    try {
      if (!js_util.hasProperty(js_util.globalThis, method)) {
        return;
      }
      js_util.callMethod(js_util.globalThis, method, args);
    } catch (_) {
      // ignora: Sentry non disponibile o JS non pronto
    }
  }
}
