// lib/Services/HinooStorageUploader.dart
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class HinooStorageUploader {
  static const String bucket = 'hinoo';
  static final _supabase = Supabase.instance.client;
  static final _uuid = const Uuid();

  static String _normalizeExt(String ext) {
    final e = ext.trim().toLowerCase();
    if (e == 'jpeg') return 'jpg';
    const allowed = {'jpg', 'png', 'webp'};
    return allowed.contains(e) ? e : 'jpg';
  }

  static String _normalizeFolder(String? folder) {
    switch (folder) {
      case 'backgrounds':
      case 'exports':
        return folder!;
      default:
        return 'backgrounds';
    }
  }

  static void _assertUserId(String userId) {
    if (userId.isEmpty || userId.contains('/')) {
      throw 'userId non valido per il path Storage';
    }
  }

  /// Upload generico in:
  ///   hinoo/<userId>/<folder>/<uuid>.<ext>
  static Future<String> uploadBytes({
    required Uint8List bytes,
    required String filenameExt, // es: "jpg" | "png" | "webp" | "jpeg"
    required String userId,
    String folder = 'backgrounds', // default sicuro
  }) async {
    _assertUserId(userId);
    final safeExt = _normalizeExt(filenameExt);
    final safeFolder = _normalizeFolder(folder);

    final id = _uuid.v4();
    final path = '$userId/$safeFolder/$id.$safeExt';

    await _supabase.storage.from(bucket).uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(
        upsert: false,
        cacheControl: 'public, max-age=31536000',
      ),
    );

    return _supabase.storage.from(bucket).getPublicUrl(path);
  }

  /// Sfondi → hinoo/<userId>/backgrounds/<uuid>.<ext>
  static Future<String> uploadBackground({
    required Uint8List bytes,
    required String ext,
    required String userId,
  }) {
    return uploadBytes(
      bytes: bytes,
      filenameExt: ext,
      userId: userId,
      folder: 'backgrounds',
    );
  }

  /// Export PNG → hinoo/<userId>/exports/<uuid>.png
  static Future<String> uploadExportPng({
    required Uint8List pngBytes,
    required String userId,
  }) {
    return uploadBytes(
      bytes: pngBytes,
      filenameExt: 'png',
      userId: userId,
      folder: 'exports',
    );
  }
}
