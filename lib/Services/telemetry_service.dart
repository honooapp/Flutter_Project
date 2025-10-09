import 'dart:async';

import 'package:flutter/foundation.dart';

import 'supabase_provider.dart';
import 'telemetry_platform_stub.dart'
    if (dart.library.html) 'telemetry_platform_web.dart';

class TelemetryService {
  TelemetryService._();

  static String? _supabaseTable;
  static bool _sentryConfigured = false;

  static void configure({String? supabaseTable, String? sentryDsn}) {
    final table = supabaseTable?.trim();
    _supabaseTable = (table == null || table.isEmpty) ? null : table;

    final dsn = sentryDsn?.trim();
    if (dsn != null && dsn.isNotEmpty) {
      TelemetryPlatform.initSentry(dsn);
      _sentryConfigured = true;
      final prefixLength = dsn.length < 8 ? dsn.length : 8;
      TelemetryPlatform.addBreadcrumb(
        'telemetry',
        'sentry_configured',
        {'dsn_prefix': dsn.substring(0, prefixLength)},
      );
    }
  }

  static Future<void> recordFetch(
    String name, {
    Duration? duration,
    int? count,
    Map<String, Object?>? extra,
  }) async {
    await recordEvent('fetch', {
      'name': name,
      if (duration != null) 'duration_ms': duration.inMilliseconds,
      if (count != null) 'count': count,
      if (extra != null) ..._sanitizeMap(extra),
    });
  }

  static Future<void> recordEvent(
    String category,
    Map<String, Object?> payload,
  ) async {
    TelemetryPlatform.addBreadcrumb(category, 'event', payload);

    final table = _supabaseTable;
    if (table == null) return;

    try {
      await SupabaseProvider.client.from(table).insert({
        'category': category,
        'payload': _sanitizeMap(payload),
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (error, stack) {
      debugPrint('TelemetryService recordEvent error: $error');
      if (_sentryConfigured) {
        TelemetryPlatform.captureException(
          error,
          stack,
          {'category': category},
        );
      }
    }
  }

  static Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String category = 'unhandled',
    Map<String, Object?>? context,
  }) async {
    TelemetryPlatform.captureException(error, stack, context);
    await recordEvent(category, {
      'error': error.toString(),
      if (stack != null) 'stack': stack.toString(),
      if (context != null) ..._sanitizeMap(context),
    });
  }

  static Map<String, Object?> _sanitizeMap(Map<String, Object?> source) {
    final sanitized = <String, Object?>{};
    source.forEach((key, value) {
      sanitized[key] = _sanitizeValue(value);
    });
    return sanitized;
  }

  static Object? _sanitizeValue(Object? value) {
    if (value == null) return null;
    if (value is num || value is bool || value is String) return value;
    if (value is DateTime) return value.toUtc().toIso8601String();
    if (value is Duration) return value.inMilliseconds;
    if (value is Iterable) {
      return value.map(_sanitizeValue).toList();
    }
    if (value is Map) {
      return value.map((key, dynamic v) => MapEntry('$key', _sanitizeValue(v)));
    }
    return value.toString();
  }
}
