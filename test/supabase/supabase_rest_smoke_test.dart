import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '_env.dart';

void main() {
  group('Supabase REST smoke', () {
    final hasEnv = env('SUPABASE_URL').isNotEmpty && env('SUPABASE_ANON_KEY').isNotEmpty;
    test('SELECT honoo limit 1',
        timeout: const Timeout(Duration(seconds: 20)),
        skip: hasEnv ? false : 'Skipping: SUPABASE_URL/ANON_KEY missing', () async {
      final url = env('SUPABASE_URL');
      final key = env('SUPABASE_ANON_KEY');
      expect(url, isNotEmpty, reason: 'SUPABASE_URL mancante');
      expect(key, isNotEmpty, reason: 'SUPABASE_ANON_KEY mancante');

      final uri = Uri.parse('$url/rest/v1/honoo?select=*&limit=1');
      final resp = await http.get(uri, headers: {
        'apikey': key,
        'Authorization': 'Bearer $key',
      }).timeout(const Duration(seconds: 15));

      expect(resp.statusCode, anyOf(200, 206),
          reason: 'HTTP ${resp.statusCode}: ${resp.body}');
      final data = jsonDecode(resp.body);
      expect(data, isA<List<dynamic>>());
    });
  });
}
