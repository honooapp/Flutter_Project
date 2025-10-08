import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '_env.dart';

void main() {
  group('Supabase REST auth', () {
    test('signInWithPassword (GoTrue)',
        timeout: const Timeout(Duration(seconds: 25)), () async {
      final url = env('SUPABASE_URL');
      final key = env('SUPABASE_ANON_KEY');
      final email = env('TEST_EMAIL');
      final password = env('TEST_PASSWORD');

      for (final v in [url, key, email, password]) {
        expect(v, isNotEmpty,
            reason:
                'Variabili mancanti: SUPABASE_URL, SUPABASE_ANON_KEY, TEST_EMAIL, TEST_PASSWORD');
      }

      final uri = Uri.parse('$url/auth/v1/token?grant_type=password');
      final resp = await http
          .post(
            uri,
            headers: {
              'apikey': key,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 20));

      expect(resp.statusCode, 200,
          reason: 'HTTP ${resp.statusCode}: ${resp.body}');
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      expect(json['access_token'], isA<String>());
      expect(json['user']?['email'], email);
    });
  });
}
