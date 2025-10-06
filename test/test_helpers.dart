import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gotrue/gotrue.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

bool _supabaseInitialized = false;
final _mockHttp = MockClient((_) async => http.Response("{}", 200));

class _InMemoryPkceStorage extends GotrueAsyncStorage {
  final _storage = HashMap<String, String>();

  @override
  Future<String?> getItem({required String key}) async => _storage[key];

  @override
  Future<void> removeItem({required String key}) async {
    _storage.remove(key);
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    _storage[key] = value;
  }
}

Future<void> ensureInitializedTestSupabase() async {
  if (_supabaseInitialized) {
    return;
  }

  await Supabase.initialize(
    url: 'https://example.supabase.co',
    anonKey: 'test-anon-key',
    localStorage: const EmptyLocalStorage(),
    httpClient: _mockHttp,
    debug: false,
    pkceAsyncStorage: _InMemoryPkceStorage(),
  );

  _supabaseInitialized = true;
}

Future<void> pumpSizerApp(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    Sizer(
      builder: (_, __, ___) => MaterialApp(home: child),
    ),
  );
  await tester.pumpAndSettle();
}
