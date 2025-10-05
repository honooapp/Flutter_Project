import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:honoo/Services/HinooStorageUploader.dart';

/// Mocks per supabase_flutter ^1.10.x
class _MockSupabaseClient extends Mock implements SupabaseClient {}
class _MockStorageClient extends Mock implements SupabaseStorageClient {}
class _MockFileApi extends Mock implements StorageFileApi {}

void main() {
  late _MockSupabaseClient client;
  late _MockStorageClient storage;
  late _MockFileApi fileApi;

  setUpAll(() {
    // Fallback per matcher su tipi posizionali/named
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(const FileOptions());
  });

  setUp(() {
    client = _MockSupabaseClient();
    storage = _MockStorageClient();
    fileApi = _MockFileApi();

    // Inietta il client mock nell'uploader
    HinooStorageUploader.$setTestClient(client);

    // catena: client.storage -> storage ; storage.from('hinoo') -> fileApi
    when(() => client.storage).thenReturn(storage);
    when(() => storage.from('hinoo')).thenReturn(fileApi);

    // Stub base (asincrono → thenAnswer)
    when(() => fileApi.uploadBinary(
      any(),                    // path
      any<Uint8List>(),         // file
      fileOptions: any(named: 'fileOptions'),
    )).thenAnswer((_) async => 'ignored-path-returned-by-upload');
    when(() => fileApi.getPublicUrl(any()))
        .thenReturn('https://cdn.example.com/hinoo/mock-url.png');
  });

  tearDown(() {
    HinooStorageUploader.$setTestClient(null);
  });

  test('uploadExportPng: usa folder exports e ritorna un URL pubblico', () async {
    final bytes = Uint8List.fromList([137, 80, 78, 71]); // header PNG

    final url = await HinooStorageUploader.uploadExportPng(
      pngBytes: bytes,
      userId: 'u1',
    );

    expect(url, contains('https://cdn.example.com/hinoo/'));

    final captured = verify(() => fileApi.uploadBinary(
      captureAny(), // path
      any<Uint8List>(),
      fileOptions: any(named: 'fileOptions', that: isA<FileOptions>()),
    )).captured;

    final String path = captured.first as String;
    // path = u1/exports/<uuid>.png
    expect(path, allOf([contains('u1/exports/'), endsWith('.png')]));
    verify(() => fileApi.getPublicUrl(path)).called(1);
  });

  test('uploadBackground: usa folder backgrounds e rispetta estensione (jpeg → jpg)', () async {
    when(() => fileApi.getPublicUrl(any()))
        .thenReturn('https://cdn.example.com/hinoo/bg.jpg');

    final url = await HinooStorageUploader.uploadBackground(
      bytes: Uint8List.fromList([1, 2, 3]),
      ext: 'jpeg', // deve essere normalizzato in 'jpg'
      userId: 'u2',
    );

    expect(url, endsWith('.jpg'));

    final captured = verify(() => fileApi.uploadBinary(
      captureAny(),
      any<Uint8List>(),
      fileOptions: any(named: 'fileOptions', that: isA<FileOptions>()),
    )).captured;

    final String path = captured.first as String;
    expect(path, allOf([contains('u2/backgrounds/'), endsWith('.jpg')]));
    verify(() => fileApi.getPublicUrl(path)).called(1);
  });

  test('uploadBytes: folder custom e normalizzazione estensioni non permesse → jpg', () async {
    when(() => fileApi.getPublicUrl(any()))
        .thenReturn('https://cdn.example.com/hinoo/custom.jpg');

    final url = await HinooStorageUploader.uploadBytes(
      bytes: Uint8List.fromList([9, 9]),
      filenameExt: 'tiff', // non ammesso → forzato a 'jpg'
      userId: 'u3',
      folder: 'backgrounds',
    );

    expect(url, endsWith('.jpg'));

    final captured = verify(() => fileApi.uploadBinary(
      captureAny(),
      any<Uint8List>(),
      fileOptions: any(named: 'fileOptions', that: isA<FileOptions>()),
    )).captured;

    final String path = captured.first as String;
    expect(path, allOf([contains('u3/backgrounds/'), endsWith('.jpg')]));
    verify(() => fileApi.getPublicUrl(path)).called(1);
  });

  test('uploadBytes: userId non valido → lancia', () async {
    expect(
          () => HinooStorageUploader.uploadBytes(
        bytes: Uint8List.fromList([0]),
        filenameExt: 'png',
        userId: 'invalid/user', // contiene '/'
      ),
      throwsA(isA<String>()),
    );
    verifyNever(() => fileApi.uploadBinary(any(), any(), fileOptions: any(named: 'fileOptions')));
  });
}
