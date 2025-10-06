import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://mulardcrjecwmohlheuz.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im11bGFyZGNyamVjd21vaGxoZXV6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM4MDgxNDYsImV4cCI6MjA2OTM4NDE0Nn0.wt0CJD8XHkGoX2qLlmQgwG6RHLUfxx6JKO9EMnpTAsc',
  );

  await testMain();
}
