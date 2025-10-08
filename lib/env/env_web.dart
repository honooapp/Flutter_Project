// lib/env/env_web.dart
// Web: String.fromEnvironment è permesso solo in contesti const (compile-time).
// Quindi definiamo COSTANTI di modulo (top-level) per ogni chiave che ci serve
// e NON invochiamo fromEnvironment a runtime.

const _supabaseUrlDefine =
    String.fromEnvironment('SUPABASE_URL', defaultValue: '');
const _supabaseAnonKeyDefine =
    String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

// Interfaccia compatibile con il resto dell'app.
String readEnv(String key, {String fallback = ''}) {
  switch (key) {
    case 'SUPABASE_URL':
      return _supabaseUrlDefine.isEmpty ? fallback : _supabaseUrlDefine;
    case 'SUPABASE_ANON_KEY':
      return _supabaseAnonKeyDefine.isEmpty
          ? fallback
          : _supabaseAnonKeyDefine;
    default:
      // Su Web gestiamo solo le chiavi note (aggiungine qui se ti servono altre define)
      return fallback;
  }
}
