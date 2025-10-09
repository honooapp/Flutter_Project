import 'dart:io';
import 'dart:async';
import 'dart:collection';

import 'package:honoo/Services/honoo_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Services/supabase_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class MockSession extends Mock implements Session {}

class MockQueryChain extends Mock
    implements
        SupabaseQueryBuilder,
        PostgrestFilterBuilder<dynamic>,
        PostgrestTransformBuilder<dynamic> {
  final Queue<dynamic> _responses = Queue<dynamic>();

  void queueResponse(dynamic value) => _responses.add(value);

  dynamic _nextResponse() {
    if (_responses.isEmpty) {
      return <String, dynamic>{};
    }
    return _responses.removeFirst();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #then &&
        invocation.positionalArguments.isNotEmpty) {
      final onValue =
          invocation.positionalArguments[0] as dynamic Function(dynamic);
      return Future.value(onValue(_nextResponse()));
    }
    return super.noSuchMethod(invocation);
  }
}

class FakeAuthState extends Fake implements AuthState {}

bool _googleFontsRegistered = false;

Future<void> registerSupabaseFallbacks() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});
  PathProviderPlatform.instance = _FakePathProviderPlatform();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('com.llfbandit.app_links/messages'),
          (call) async {
    switch (call.method) {
      case 'getInitialAppLink':
      case 'getInitialLink':
        return null;
      case 'getLatestAppLink':
      case 'getLatestLink':
        return null;
      default:
        return null;
    }
  });
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('com.llfbandit.app_links/events'), (call) async {
    switch (call.method) {
      case 'listen':
      case 'cancel':
        return null;
      default:
        return null;
    }
  });
  registerFallbackValue(<String, dynamic>{});
  registerFallbackValue(FakeAuthState());
  registerFallbackValue(OtpType.email);

  if (!_googleFontsRegistered) {
    GoogleFonts.config.allowRuntimeFetching = false;
    await Future.wait([
      _loadGoogleFontFamily('Libre Franklin', const [
        'assets/google_fonts/LibreFranklin-VariableFont_wght.ttf',
        'assets/google_fonts/LibreFranklin-Medium.ttf',
        'assets/google_fonts/LibreFranklin-Italic-VariableFont_wght.ttf',
      ]),
      _loadGoogleFontFamily('Arvo', const [
        'assets/google_fonts/Arvo-Regular.ttf',
        'assets/google_fonts/Arvo-Bold.ttf',
        'assets/google_fonts/Arvo-Italic.ttf',
        'assets/google_fonts/Arvo-BoldItalic.ttf',
      ]),
      _loadGoogleFontFamily('Lora', const [
        'assets/google_fonts/Lora-VariableFont_wght.ttf',
        'assets/google_fonts/Lora-Italic-VariableFont_wght.ttf',
      ]),
    ]);
    _googleFontsRegistered = true;
  }
}

Future<void> _loadGoogleFontFamily(
  String family,
  List<String> assetPaths,
) async {
  final loader = FontLoader(family);
  for (final asset in assetPaths) {
    loader.addFont(rootBundle.load(asset));
  }
  await loader.load();
}

class SupabaseTestHarness {
  SupabaseTestHarness({bool withAuthenticatedUser = false}) {
    when(() => client.auth).thenReturn(auth);
    when(() => auth.currentSession)
        .thenReturn(withAuthenticatedUser ? session : null);
    when(() => auth.currentUser)
        .thenReturn(withAuthenticatedUser ? user : null);
    when(() => user.id).thenReturn('test_user');
    when(() => session.user).thenReturn(user);
    when(() => auth.onAuthStateChange)
        .thenAnswer((_) => const Stream<AuthState>.empty());
    when(() => auth.signInWithOtp(email: any(named: 'email'))).thenAnswer(
        (_) async => AuthResponse(
            session: session, user: withAuthenticatedUser ? user : null));
    when(() => auth.verifyOTP(
              type: any(named: 'type'),
              email: any(named: 'email'),
              token: any(named: 'token'),
            ))
        .thenAnswer((_) async => AuthResponse(
            session: session, user: withAuthenticatedUser ? user : null));
  }

  final MockSupabaseClient client = MockSupabaseClient();
  final MockGoTrueClient auth = MockGoTrueClient();
  final MockUser user = MockUser();
  final MockSession session = MockSession();

  void enableOverrides() {
    SupabaseProvider.overrideForTests(client);
    HonooService.$setTestClient(client);
    HonooService.$clearCacheForTests();
  }

  void disableOverrides() {
    SupabaseProvider.overrideForTests(null);
    HonooService.$clearCacheForTests();
    HonooService.$setTestClient(null);
  }

  MockQueryChain stubTable(String table) {
    final chain = MockQueryChain();
    when(() => client.from(table)).thenAnswer((_) => chain);
    when(() => chain.select(any())).thenAnswer((_) => chain);
    when(() => chain.insert(any())).thenAnswer((_) => chain);
    when(() => chain.eq(any(), any())).thenAnswer((_) => chain);
    when(() => chain.order(any(), ascending: any(named: 'ascending')))
        .thenAnswer((_) => chain);
    when(() => chain.limit(any())).thenAnswer((_) => chain);
    when(() => chain.lt(any(), any())).thenAnswer((_) => chain);
    when(() => chain.or(any())).thenAnswer((_) => chain);
    when(() => chain.in_(any(), any())).thenAnswer((_) => chain);
    when(() => chain.delete()).thenAnswer((_) => chain);
    when(() => chain.update(any())).thenAnswer((_) => chain);
    when(() => chain.maybeSingle()).thenAnswer((_) => chain);
    return chain;
  }
}

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform() {
    _tempDir = Directory.systemTemp.createTempSync('path_provider_test');
  }

  late final Directory _tempDir;

  @override
  Future<String?> getTemporaryPath() async => _tempDir.path;

  @override
  Future<String?> getApplicationSupportPath() async => _tempDir.path;

  @override
  Future<String?> getLibraryPath() async => _tempDir.path;

  @override
  Future<String?> getApplicationDocumentsPath() async => _tempDir.path;

  @override
  Future<String?> getApplicationCachePath() async => _tempDir.path;

  @override
  Future<String?> getExternalStoragePath() async => _tempDir.path;

  @override
  Future<List<String>?> getExternalCachePaths() async =>
      <String>[_tempDir.path];

  @override
  Future<List<String>?> getExternalStoragePaths(
          {StorageDirectory? type}) async =>
      <String>[_tempDir.path];

  @override
  Future<String?> getDownloadsPath() async => _tempDir.path;
}
