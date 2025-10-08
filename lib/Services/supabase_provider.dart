import 'package:supabase_flutter/supabase_flutter.dart';

/// Punto centralizzato per ottenere il client di Supabase ed eventualmente
/// sovrascriverlo nei test senza dover toccare tutto il codice di produzione.
class SupabaseProvider {
  SupabaseProvider._();

  static SupabaseClient? _overrideClient;

  /// Restituisce il client da usare. In produzione usa Supabase.instance,
  /// nei test possiamo fornire un mock con [overrideForTests].
  static SupabaseClient get client =>
      _overrideClient ?? Supabase.instance.client;

  /// Permette ai test di iniettare un client personalizzato. Passa `null`
  /// per ripristinare il comportamento predefinito.
  static void overrideForTests(SupabaseClient? client) {
    _overrideClient = client;
  }
}
