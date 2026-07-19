import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

enum AppFailureKind {
  offline,
  sessionExpired,
  rlsDenied,
  timeout,
  backendUnavailable,
  invalidData,
}

class AppFailure implements Exception {
  const AppFailure(
    this.kind, {
    this.cause,
    this.stackTrace,
  });

  final AppFailureKind kind;
  final Object? cause;
  final StackTrace? stackTrace;

  factory AppFailure.from(Object error, [StackTrace? stackTrace]) {
    if (error is AppFailure) return error;
    if (error is TimeoutException) {
      return AppFailure(AppFailureKind.timeout,
          cause: error, stackTrace: stackTrace);
    }
    if (error is SocketException) {
      return AppFailure(AppFailureKind.offline,
          cause: error, stackTrace: stackTrace);
    }
    if (error is FormatException) {
      return AppFailure(AppFailureKind.invalidData,
          cause: error, stackTrace: stackTrace);
    }
    if (error is AuthException) {
      final status = error.statusCode?.toString();
      final message = error.message.toLowerCase();
      final expired = status == '401' ||
          message.contains('expired') ||
          message.contains('session') ||
          message.contains('token');
      return AppFailure(
        expired
            ? AppFailureKind.sessionExpired
            : AppFailureKind.backendUnavailable,
        cause: error,
        stackTrace: stackTrace,
      );
    }
    if (error is PostgrestException) {
      final code = error.code ?? '';
      if (code == '42501' || code == 'PGRST301') {
        return AppFailure(AppFailureKind.rlsDenied,
            cause: error, stackTrace: stackTrace);
      }
      if (code.startsWith('22') ||
          code == '23502' ||
          code == '23503' ||
          code == '23505') {
        return AppFailure(AppFailureKind.invalidData,
            cause: error, stackTrace: stackTrace);
      }
      return AppFailure(AppFailureKind.backendUnavailable,
          cause: error, stackTrace: stackTrace);
    }
    return AppFailure(AppFailureKind.backendUnavailable,
        cause: error, stackTrace: stackTrace);
  }

  @override
  String toString() => 'AppFailure(kind: $kind, cause: $cause)';
}
