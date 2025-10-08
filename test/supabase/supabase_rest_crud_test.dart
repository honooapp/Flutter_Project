import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

// Helpers
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
    case 'TEST_EMAIL':
      return const String.fromEnvironment('TEST_EMAIL', defaultValue: '');
    case 'TEST_PASSWORD':
      return const String.fromEnvironment('TEST_PASSWORD', defaultValue: '');
    case 'ENABLE_WRITE_TESTS':
      return const String.fromEnvironment('ENABLE_WRITE_TESTS',
          defaultValue: '');
    default:
      return '';
  }
}

Future<String> _signInAndGetAccessToken({
  required String url,
  required String anonKey,
  required String email,
  required String password,
}) async {
  final uri = Uri.parse('$url/auth/v1/token?grant_type=password');
  final resp = await http
      .post(uri,
          headers: {'apikey': anonKey, 'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}))
      .timeout(const Duration(seconds: 20));
  if (resp.statusCode != 200) {
    throw StateError('Auth failed ${resp.statusCode}: ${resp.body}');
  }
  final json = jsonDecode(resp.body) as Map<String, dynamic>;
  final token = json['access_token'] as String?;
  if (token == null || token.isEmpty) {
    throw StateError('Missing access_token');
  }
  return token;
}

void main() {
  final baseUrl = env('SUPABASE_URL');
  final anonKey = env('SUPABASE_ANON_KEY');
  final email = env('TEST_EMAIL');
  final password = env('TEST_PASSWORD');
  final enableWrites = env('ENABLE_WRITE_TESTS') == '1';

  group('Supabase REST CRUD (e2e_items)', () {
    if (!enableWrites) {
      test('Scritture disabilitate (set ENABLE_WRITE_TESTS=1 per abilitare)',
          () {
        expect(enableWrites, isFalse);
      });
      return;
    }

    late String bearer;
    late String createdId;

    setUpAll(() async {
      final requiredEnv = <String, String>{
        'SUPABASE_URL': baseUrl,
        'SUPABASE_ANON_KEY': anonKey,
        'TEST_EMAIL': email,
        'TEST_PASSWORD': password,
      };
      requiredEnv.forEach((key, value) {
        if (value.isEmpty) {
          throw StateError('Env mancante: $key');
        }
      });
      bearer = await _signInAndGetAccessToken(
        url: baseUrl,
        anonKey: anonKey,
        email: email,
        password: password,
      );
    });

    test('INSERT (creates test row)',
        timeout: const Timeout(Duration(seconds: 20)), () async {
      final uri = Uri.parse('$baseUrl/rest/v1/e2e_items');
      final resp = await http
          .post(uri,
              headers: {
                'apikey': anonKey,
                'Authorization': 'Bearer $bearer',
                'Content-Type': 'application/json',
                'Prefer': 'return=representation' // ritorna la riga creata
              },
              body: jsonEncode({
                // user_id sarà impostato da default auth.uid()
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
      expect(row['is_test'], isTrue); // policy/flag
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
