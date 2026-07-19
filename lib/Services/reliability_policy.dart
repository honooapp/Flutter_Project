import 'dart:async';

import 'app_failure.dart';

typedef AsyncOperation = dynamic Function();

/// Policy comune per le operazioni backend. Le scritture non vengono ritentate
/// automaticamente: un retry cieco può duplicare insert non idempotenti.
class ReliabilityPolicy {
  const ReliabilityPolicy({
    this.readTimeout = const Duration(seconds: 10),
    this.writeTimeout = const Duration(seconds: 15),
    this.refreshTimeout = const Duration(seconds: 10),
    this.readRetries = 1,
    this.refreshRetries = 1,
  });

  final Duration readTimeout;
  final Duration writeTimeout;
  final Duration refreshTimeout;
  final int readRetries;
  final int refreshRetries;

  Future<T> read<T>(AsyncOperation operation) =>
      _run(operation, timeout: readTimeout, retries: readRetries);

  Future<T> write<T>(AsyncOperation operation) =>
      _run(operation, timeout: writeTimeout);

  Future<T> refresh<T>(AsyncOperation operation) =>
      _run(operation, timeout: refreshTimeout, retries: refreshRetries);

  Future<T> _run<T>(
    AsyncOperation operation, {
    required Duration timeout,
    int retries = 0,
  }) async {
    for (var attempt = 0;; attempt++) {
      try {
        // Alcuni mock legacy di Supabase restituiscono null quando una
        // chiamata non è stub-bata: gestiamo entrambi i casi senza perdere il
        // timeout sulle Future reali.
        final pending = Future<dynamic>.sync(operation);
        return await pending.timeout(timeout) as T;
      } catch (error, stackTrace) {
        final failure = AppFailure.from(error, stackTrace);
        if (attempt >= retries || !_canRetry(failure)) throw failure;
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
    }
  }

  bool _canRetry(AppFailure failure) =>
      failure.kind == AppFailureKind.offline ||
      failure.kind == AppFailureKind.timeout ||
      failure.kind == AppFailureKind.backendUnavailable;
}
