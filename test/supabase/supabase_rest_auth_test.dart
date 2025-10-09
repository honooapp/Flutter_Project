import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

import 'package:honoo/Services/auth_service.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late _MockSupabaseClient client;
  late _MockGoTrueClient auth;
  late AuthService service;

  setUp(() {
    client = _MockSupabaseClient();
    auth = _MockGoTrueClient();
    when(() => client.auth).thenReturn(auth);
    service = AuthService(client: client);
  });

  test('requestMagicLink delega a signInWithOtp', () async {
    when(
      () => auth.signInWithOtp(
        email: 'user@example.com',
        emailRedirectTo: 'https://app.test/otp',
        data: null,
        shouldCreateUser: null,
        captchaToken: null,
        channel: OtpChannel.sms,
      ),
    ).thenAnswer((_) async {});

    await service.requestMagicLink(
      'user@example.com',
      redirectUrl: 'https://app.test/otp',
    );

    verify(
      () => auth.signInWithOtp(
        email: 'user@example.com',
        emailRedirectTo: 'https://app.test/otp',
        data: null,
        shouldCreateUser: null,
        captchaToken: null,
        channel: OtpChannel.sms,
      ),
    ).called(1);
  });

  test('registerEmailOnly crea utente via OTP flow', () async {
    final metadata = {'source': 'test'};

    when(
      () => auth.signInWithOtp(
        email: 'new@example.com',
        emailRedirectTo: 'app://redirect',
        data: metadata,
        shouldCreateUser: true,
        captchaToken: null,
        channel: OtpChannel.sms,
      ),
    ).thenAnswer((_) async {});

    await service.registerEmailOnly(
      'new@example.com',
      data: metadata,
      redirectUrl: 'app://redirect',
    );

    verify(
      () => auth.signInWithOtp(
        email: 'new@example.com',
        emailRedirectTo: 'app://redirect',
        data: metadata,
        shouldCreateUser: true,
        captchaToken: null,
        channel: OtpChannel.sms,
      ),
    ).called(1);
  });
}
