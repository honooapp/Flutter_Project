import 'dart:developer' as developer;

/// Logging centralizzato. Non passare token, password o payload sensibili.
class AppLogger {
  const AppLogger._();

  static void info(String message, {String scope = 'honoo'}) {
    developer.log(message, name: scope);
  }

  static void warning(
    String message, {
    String scope = 'honoo',
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: scope,
      error: error,
      stackTrace: stackTrace,
      level: 900,
    );
  }

  static void error(
    String message, {
    String scope = 'honoo',
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: scope,
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }
}
