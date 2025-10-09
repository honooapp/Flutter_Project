import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '_env.dart';

void main() {
  group('Supabase REST storage', () {
    test('Public image reachable',
        timeout: const Timeout(Duration(seconds: 20)), () async {
      final url = env('TEST_IMAGE_URL');
      if (url.isEmpty) {
        stdout.writeln('Skipping Supabase REST storage: missing TEST_IMAGE_URL');
        return;
      }

      final resp =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      expect(resp.statusCode, 200, reason: 'HTTP ${resp.statusCode}');
      expect(resp.bodyBytes.length, greaterThan(100));
    });
  });
}
