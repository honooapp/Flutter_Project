import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

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
      error: kReleaseMode ? error?.runtimeType : error,
      stackTrace: kReleaseMode ? null : stackTrace,
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
      error: kReleaseMode ? error?.runtimeType : error,
      stackTrace: kReleaseMode ? null : stackTrace,
      level: 1000,
    );
  }
}
