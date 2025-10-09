// TODO: set redirectUrl dagli env/build flavors (WEB/ANDROID/IOS).
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> requestMagicLink(String email, {String? redirectUrl}) async {
    await _client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: redirectUrl,
    );
  }

  Future<void> registerEmailOnly(
    String email, {
    Map<String, dynamic>? data,
    String? redirectUrl,
  }) async {
    await _client.auth.signInWithOtp(
      email: email,
      data: data,
      shouldCreateUser: true,
      // Supabase invia il magic link di conferma, nessuna password.
      emailRedirectTo: redirectUrl,
    );
  }
}
