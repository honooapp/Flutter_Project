// lib/Services/HonooImageUploader.dart
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class HonooImageUploader {
  static final _client = Supabase.instance.client;
  static const String _bucket = 'honoo-images'; // <-- bucket pubblico

  /// Mobile (Android/iOS): carica da path locale e restituisce la public URL.
  static Future<String?> uploadImageFromPath(String path) async {
    try {
      // === 0) Guardia autenticazione ===
      final session = _client.auth.currentSession;
      if (session == null) {
        debugPrint('uploadImageFromPath: sessione assente');
        return null;
      }
      final uid = session.user.id;

      final bytes = await File(path).readAsBytes();
      final ext = _extFromPath(path);
      final fileName = '${const Uuid().v4()}$ext';
      final storagePath = '$uid/uploads/$fileName'; // per-utente

      await _client.storage.from(_bucket).uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              upsert: false,
              contentType: _contentTypeFromExt(ext),
            ),
          );

      return _client.storage.from(_bucket).getPublicUrl(storagePath);
    } catch (e) {
      debugPrint('uploadImageFromPath error: $e');
      return null;
    }
  }

  /// Web o fallback generale: carica bytes + estensione e restituisce la public URL.
  static Future<String?> uploadImageBytes(Uint8List bytes, String ext) async {
    try {
      // === 0) Guardia autenticazione ===
      final session = _client.auth.currentSession;
      if (session == null) {
        debugPrint('uploadImageBytes: sessione assente');
        return null;
      }
      final uid = session.user.id;

      final fileName = '${const Uuid().v4()}$ext';
      final storagePath = '$uid/uploads/$fileName'; // per-utente

      await _client.storage.from(_bucket).uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              upsert: false,
              contentType: _contentTypeFromExt(ext),
            ),
          );

      return _client.storage.from(_bucket).getPublicUrl(storagePath);
    } catch (e) {
      debugPrint('uploadImageBytes error: $e');
      return null;
    }
  }

  static String _extFromPath(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0) return '.jpg';
    final ext = path.substring(dot).trim().toLowerCase();
    if (ext.isEmpty || ext.length > 5) return '.jpg';
    return ext;
  }

  static String _contentTypeFromExt(String ext) {
    final e = ext.toLowerCase();
    if (e.endsWith('png')) return 'image/png';
    if (e.endsWith('webp')) return 'image/webp';
    if (e.endsWith('gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
