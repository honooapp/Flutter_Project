// lib/env/env_web.dart
// Web: String.fromEnvironment è permesso solo in contesti const (compile-time).
// Quindi definiamo COSTANTI di modulo (top-level) per ogni chiave che ci serve
// e NON invochiamo fromEnvironment a runtime.

const _SUPABASE_URL = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
const _SUPABASE_ANON_KEY = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

// Interfaccia compatibile con il resto dell'app.
String readEnv(String key, {String fallback = ''}) {
  switch (key) {
    case 'SUPABASE_URL':
      return _SUPABASE_URL.isEmpty ? fallback : _SUPABASE_URL;
    case 'SUPABASE_ANON_KEY':
      return _SUPABASE_ANON_KEY.isEmpty ? fallback : _SUPABASE_ANON_KEY;
    default:
      // Su Web gestiamo solo le chiavi note (aggiungine qui se ti servono altre define)
      return fallback;
  }
}
