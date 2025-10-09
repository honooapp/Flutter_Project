import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

// In passwordless mode usiamo un bearer token ottenuto via magic link/OTP.
// Impostalo con TEST_BEARER_TOKEN prima di abilitare i test di scrittura.
const _bearerEnvKey = 'TEST_BEARER_TOKEN';

String env(String k) {
  final fromDefine = _fromDefines(k);
  if (fromDefine.isNotEmpty) {
    return fromDefine;
  }
  return Platform.environment[k] ?? '';
}

String _fromDefines(String key) {
  switch (key) {
    case 'SUPABASE_URL':
      return const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    case 'SUPABASE_ANON_KEY':
      return const String.fromEnvironment('SUPABASE_ANON_KEY',
          defaultValue: '');
    case _bearerEnvKey:
      return const String.fromEnvironment(_bearerEnvKey, defaultValue: '');
    case 'ENABLE_WRITE_TESTS':
      return const String.fromEnvironment('ENABLE_WRITE_TESTS',
          defaultValue: '');
    default:
      return '';
  }
}

void main() {
  final baseUrl = env('SUPABASE_URL');
  final anonKey = env('SUPABASE_ANON_KEY');
  final bearer = env(_bearerEnvKey);
  final enableWrites = env('ENABLE_WRITE_TESTS') == '1';

  group('Supabase REST CRUD (OTP session)', () {
    if (!enableWrites) {
      test('Scritture disabilitate (set ENABLE_WRITE_TESTS=1 per abilitare)',
          () {
        expect(enableWrites, isFalse);
      });
      return;
    }

    if ([baseUrl, anonKey, bearer].any((value) => value.isEmpty)) {
      test('Env mancanti per i test Supabase', () {
        fail('Env mancanti');
      }, skip: 'passwordless mode: set SUPABASE_URL, SUPABASE_ANON_KEY e TEST_BEARER_TOKEN per abilitare i test di integrazione.');
      return;
    }

    late String createdId;

    test('INSERT (creates test row)',
        timeout: const Timeout(Duration(seconds: 20)), () async {
      final uri = Uri.parse('$baseUrl/rest/v1/e2e_items');
      final resp = await http
          .post(uri,
              headers: {
                'apikey': anonKey,
                'Authorization': 'Bearer $bearer',
                'Content-Type': 'application/json',
                'Prefer': 'return=representation'
              },
              body: jsonEncode({
                'label': 'live-insert-${DateTime.now().toIso8601String()}',
                'is_test': true,
              }))
          .timeout(const Duration(seconds: 15));

      expect(resp.statusCode, anyOf(200, 201),
          reason: 'HTTP ${resp.statusCode}: ${resp.body}');
      final rows = jsonDecode(resp.body) as List<dynamic>;
      expect(rows, isNotEmpty);
      createdId = (rows.first as Map<String, dynamic>)['id'] as String;
      expect(createdId, isNotEmpty);
    });

    test('UPDATE (mutates test row)',
        timeout: const Timeout(Duration(seconds: 20)), () async {
      expect(createdId, isNotEmpty, reason: 'INSERT non ha creato id');
      final uri = Uri.parse('$baseUrl/rest/v1/e2e_items?id=eq.$createdId');
      final resp = await http
          .patch(uri,
              headers: {
                'apikey': anonKey,
                'Authorization': 'Bearer $bearer',
                'Content-Type': 'application/json',
                'Prefer': 'return=representation'
              },
              body: jsonEncode({
                'label': 'live-update-${DateTime.now().millisecondsSinceEpoch}',
              }))
          .timeout(const Duration(seconds: 15));
      expect(resp.statusCode, anyOf(200, 204),
          reason: 'HTTP ${resp.statusCode}: ${resp.body}');
    });

    test('SELECT (verify own row)',
        timeout: const Timeout(Duration(seconds: 20)), () async {
      final uri = Uri.parse(
          '$baseUrl/rest/v1/e2e_items?select=*&id=eq.$createdId&limit=1');
      final resp = await http.get(uri, headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $bearer',
      }).timeout(const Duration(seconds: 15));
      expect(resp.statusCode, anyOf(200, 206),
          reason: 'HTTP ${resp.statusCode}: ${resp.body}');
      final rows = jsonDecode(resp.body) as List<dynamic>;
      expect(rows.length, 1);
      final row = rows.first as Map<String, dynamic>;
      expect(row['is_test'], isTrue);
    });

    tearDownAll(() async {
      if (createdId.isEmpty) return;
      final uri = Uri.parse('$baseUrl/rest/v1/e2e_items?id=eq.$createdId');
      await http.delete(uri, headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $bearer',
      }).timeout(const Duration(seconds: 10));
    });
  });
}
