import 'package:supabase_flutter/supabase_flutter.dart';

// Internal guard to ensure we initialize Supabase only once in tests.
bool _testSupabaseInitialized = false;

/// Initializes a dummy Supabase instance for tests so that
/// Supabase.instance is available without hitting the network.
///
/// Call this at the start of widget/integration tests, before pumping MyApp().
Future<void> initializeTestSupabase() async {
  if (_testSupabaseInitialized) return;
  if (Supabase.instance.isInitialized) {
    _testSupabaseInitialized = true;
    return;
  }
  try {
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: 'test-anon-key',
    );
  } finally {
    // Even if initialize throws (e.g., already initialized by another helper),
    // avoid retry loops in tests.
    _testSupabaseInitialized = true;
  }
}
