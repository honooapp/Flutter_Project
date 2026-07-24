import 'package:flutter/foundation.dart';

import 'app_logger.dart';
import 'build_metadata.dart';

@immutable
class DiagnosticEvent {
  const DiagnosticEvent({
    required this.code,
    required this.scope,
    required this.errorType,
    required this.buildSha,
    required this.occurredAt,
  });

  final String code;
  final String scope;
  final String errorType;
  final String buildSha;
  final DateTime occurredAt;
}

/// Diagnostica locale e limitata: non memorizza messaggi, payload o ID utente.
class AppDiagnostics {
  const AppDiagnostics._();

  static const _maxEvents = 40;
  static final List<DiagnosticEvent> _events = <DiagnosticEvent>[];

  static List<DiagnosticEvent> get recentEvents => List.unmodifiable(_events);

  static void installGlobalHandlers() {
    final previousFlutterHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      record(
        code: 'flutter_framework_error',
        scope: 'global',
        error: details.exception,
      );
      previousFlutterHandler?.call(details);
    };

    final previousPlatformHandler = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      record(code: 'unhandled_platform_error', scope: 'global', error: error);
      return previousPlatformHandler?.call(error, stackTrace) ?? false;
    };
  }

  static void record({
    required String code,
    required String scope,
    Object? error,
  }) {
    final event = DiagnosticEvent(
      code: code,
      scope: scope,
      errorType: error?.runtimeType.toString() ?? 'none',
      buildSha: BuildMetadata.shortSha,
      occurredAt: DateTime.now().toUtc(),
    );
    _events.add(event);
    if (_events.length > _maxEvents) _events.removeAt(0);

    AppLogger.error(
      '$code [build=${event.buildSha}, type=${event.errorType}]',
      scope: scope,
    );
  }

  @visibleForTesting
  static void clearForTests() => _events.clear();
}
