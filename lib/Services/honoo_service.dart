import 'dart:async';

import 'package:honoo/Services/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Entities/honoo.dart';
import 'telemetry_service.dart';

class HonooService {
  //sostituisci fuori dal test con il tuo client
  //static final _client = Supabase.instance.client;

  // ✅ Usa un getter, così nei test possiamo sovrascrivere il client
  static SupabaseClient get _client =>
      _overrideClient ?? SupabaseProvider.client;

  // ✅ Campo usato solo nei test (rimane null in produzione)
  static SupabaseClient? _overrideClient;

  static const Duration _cacheDuration = Duration(minutes: 1);
  static const int defaultPageSize = 20;
  static final Map<String, _HonooCacheEntry> _cache = {};
  static final Map<String, Future<List<Honoo>>> _inflight = {};

  static const String _baseSelect =
      'id,text,image_url,destination,reply_to,recipient_tag,created_at,updated_at,user_id,is_from_moon_saved,has_replies';

  /// TEST-ONLY: abilita injection del client mock
  static void $setTestClient(SupabaseClient? c) => _overrideClient = c;

  /// TEST-ONLY: resetta cache interna per isolare gli scenari.
  static void $clearCacheForTests() => _invalidateAllCaches();

  /// Honoo pubblici (Luna)
  static Future<List<Honoo>> fetchPublicHonoo({
    int limit = defaultPageSize,
    DateTime? before,
  }) =>
      _fetchWithCache(
        before == null ? 'public_moon_limit_$limit' : null,
        () async {
          final stopwatch = Stopwatch()..start();
          var query = _client
              .from('honoo')
              .select(_baseSelect)
              .eq('destination', 'moon');

          if (before != null) {
            query = query.lt('created_at', _isoString(before));
          }

          final response = await query
              .order('created_at', ascending: false)
              .limit(limit);
          final list = _mapToHonooList(response);

          unawaited(TelemetryService.recordFetch(
            'honoo_public',
            duration: stopwatch.elapsed,
            count: list.length,
            extra: {
              'before': before?.toIso8601String(),
              'limit': limit,
            },
          ));

          return list;
        },
      );

  /// Honoo dell’utente per una certa destination (es. 'chest')
  static Future<List<Honoo>> fetchUserHonoo(
    String userId,
    String destination, {
    int limit = defaultPageSize,
    DateTime? before,
  }) =>
      _fetchWithCache(
        before == null ? 'user_${userId}_${destination}_limit_$limit' : null,
        () async {
          final stopwatch = Stopwatch()..start();
          var query = _client
              .from('honoo')
              .select(_baseSelect)
              .eq('destination', destination)
              .eq('user_id', userId);

          if (before != null) {
            query = query.lt('created_at', _isoString(before));
          }

          final response = await query
              .order('created_at', ascending: false)
              .limit(limit);
          final list = _mapToHonooList(response);

          unawaited(TelemetryService.recordFetch(
            'honoo_user_$destination',
            duration: stopwatch.elapsed,
            count: list.length,
            extra: {
              'before': before?.toIso8601String(),
              'limit': limit,
            },
          ));

          return list;
        },
      );

  /// Tutte le reply indirizzate a recipientTag (se usi i tag poetici)
  static Future<List<Honoo>> fetchRepliesForUser(
    String recipientTag, {
    int limit = defaultPageSize,
    DateTime? before,
  }) =>
      _fetchWithCache(
        before == null ? 'replies_${recipientTag}_limit_$limit' : null,
        () async {
          final stopwatch = Stopwatch()..start();
          var query = _client
              .from('honoo')
              .select(_baseSelect)
              .eq('destination', 'reply')
              .eq('recipient_tag', recipientTag);

          if (before != null) {
            query = query.lt('created_at', _isoString(before));
          }

          final response = await query
              .order('created_at', ascending: false)
              .limit(limit);
          final list = _mapToHonooList(response);

          unawaited(TelemetryService.recordFetch(
            'honoo_replies',
            duration: stopwatch.elapsed,
            count: list.length,
            extra: {
              'recipient': recipientTag,
              'before': before?.toIso8601String(),
              'limit': limit,
            },
          ));

          return list;
        },
      );

  /// Pubblica un nuovo honoo
  static Future<void> publishHonoo(Honoo honoo) async {
    await _client.from('honoo').insert(honoo.toInsertMap());
    _invalidateAllCaches();
    unawaited(TelemetryService.recordEvent('honoo_publish', {
      'destination': honoo.type.name,
    }));
  }

  /// Aggiorna la destination (chest|moon|reply) per id (UUID DB)
  static Future<void> updateDestination({
    required String id,
    required String destination,
  }) async {
    await _client.from('honoo').update({
      'destination': destination,
    }).eq('id', id);
    _invalidateAllCaches();
    unawaited(TelemetryService.recordEvent('honoo_update_destination', {
      'destination': destination,
    }));
  }

  /// Duplica un honoo salvandolo nello scrigno dell'utente corrente.
  /// Restituisce true se inserito ora, false se già presente.
  static Future<bool> duplicateToChest(Honoo h) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw Exception('Nessuna sessione attiva');
    }
    final uid = session.user.id;

    final existing = await _client
        .from('honoo')
        .select('id')
        .eq('user_id', uid)
        .eq('destination', 'chest')
        .eq('text', h.text)
        .eq('image_url', h.image.isEmpty ? null : h.image)
        .limit(1);

    if (existing != null && existing.isNotEmpty) {
      return false;
    }

    final payload = <String, dynamic>{
      'text': h.text,
      'image_url': h.image.isEmpty ? null : h.image,
      'destination': 'chest',
      'reply_to': h.replyTo,
      'recipient_tag': h.recipientTag,
      'user_id': uid,
    };

    final inserted =
        await _client.from('honoo').insert(payload).select().maybeSingle();

    _invalidateAllCaches();
    unawaited(TelemetryService.recordEvent('honoo_duplicate_chest', {
      'inserted': inserted != null,
    }));
    return inserted != null;
  }

  /// Duplica un honoo dello scrigno pubblicandolo sulla Luna (nuova INSERT).
  /// Non tocca l'originale in 'chest'.
  static Future<bool> duplicateToMoon(Honoo h) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw Exception('Nessuna sessione attiva');
    }
    final uid = session.user.id;

    // esiste già?
    final existing = await _client
        .from('honoo')
        .select('id')
        .eq('user_id', uid)
        .eq('destination', 'moon')
        .eq('text', h.text)
        .eq('image_url', (h.image.isEmpty) ? null : h.image)
        .limit(1);

    if (existing != null && existing.isNotEmpty) {
      // già presente
      return false;
    }

    // inserisci
    final payload = <String, dynamic>{
      'text': h.text,
      'image_url': (h.image.isEmpty) ? null : h.image,
      'destination': 'moon',
      'reply_to': null,
      'recipient_tag': null,
      'user_id': uid, // se hai un trigger che lo mette da solo, puoi ometterlo
    };
    await _client.from('honoo').insert(payload);
    _invalidateAllCaches();
    unawaited(TelemetryService.recordEvent('honoo_duplicate_moon', {
      'inserted': true,
    }));
    return true;
  }

  /// Hard delete dal DB (tabella 'honoo')
  static Future<void> deleteHonooById(String id) async {
    await _client.from('honoo').delete().eq('id', id);
    _invalidateAllCaches();
    unawaited(TelemetryService.recordEvent('honoo_delete', {
      'id': id,
    }));
  }

  static Future<List<Honoo>> _fetchWithCache(
    String? key,
    Future<List<Honoo>> Function() loader,
  ) async {
    if (key != null) {
      final cached = _cache[key];
      if (cached != null &&
          DateTime.now().difference(cached.timestamp) <= _cacheDuration) {
        return _cloneHonooList(cached.items);
      }

      final inflight = _inflight[key];
      if (inflight != null) {
        final result = await inflight;
        return _cloneHonooList(result);
      }

      final future = loader();
      _inflight[key] = future;
      try {
        final fetched = await future;
        final cloned = _cloneHonooList(fetched);
        _cache[key] = _HonooCacheEntry(cloned, DateTime.now());
        return _cloneHonooList(cloned);
      } finally {
        _inflight.remove(key);
      }
    }

    final result = await loader();
    return _cloneHonooList(result);
  }

  static List<Honoo> _mapToHonooList(dynamic response) {
    if (response == null) {
      return const [];
    }
    if (response is! List) {
      return const [];
    }
    return response
        .whereType<Map<String, dynamic>>()
        .map(Honoo.fromMap)
        .toList(growable: false);
  }

  static List<Honoo> _cloneHonooList(List<Honoo> source) =>
      source.map((h) => h.copyWith()).toList(growable: false);

  static void _invalidateAllCaches() {
    _cache.clear();
    _inflight.clear();
  }

  static String _isoString(DateTime value) => value.toUtc().toIso8601String();
}

class _HonooCacheEntry {
  _HonooCacheEntry(this.items, this.timestamp);

  final List<Honoo> items;
  final DateTime timestamp;
}
