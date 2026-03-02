import 'package:supabase_flutter/supabase_flutter.dart';

// Internal guard to ensure we initialize Supabase only once in tests.
bool _testSupabaseInitialized = false;

/// Initializes a dummy Supabase instance for tests so that
/// Supabase.instance is available without hitting the network.
///
/// Call this at the start of widget/integration tests, before pumping MyApp().
Future<void> initializeTestSupabase() async {
  if (_testSupabaseInitialized) return;
  // Some SDK versions don't expose `isInitialized`. Accessing `instance.client`
  // will throw if not initialized; if it succeeds we can return.
  try {
    // ignore: unnecessary_statements
    Supabase.instance.client;
    _testSupabaseInitialized = true;
    return;
  } catch (_) {
    // Not initialized yet
  }
  try {
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: 'test-anon-key',
    );
  } finally {
    // Even if initialize throws (e.g., racing initializations),
    // avoid retry loops in tests.
    _testSupabaseInitialized = true;
  }
}
