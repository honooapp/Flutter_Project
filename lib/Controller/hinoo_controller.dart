// lib/Controller/hinoo_controller.dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:honoo/Services/supabase_provider.dart';
import 'package:honoo/Services/hinoo_service.dart';
import 'package:honoo/Services/hinoo_storage_uploader.dart';

import '../Entities/hinoo.dart';

enum HinooMoonResult { published, alreadyPresent }

class HinooController {
  String? lastSavedFingerprint;

  List<String> validateDraft(HinooDraft draft) {
    final errors = <String>[];
    final n = draft.pages.length;
    if (n < 1) errors.add('Devi completare l\'hinoo.');
    if (n > 9) errors.add('Puoi creare al massimo 9 pagine per un hinoo.');
    for (var i = 0; i < n; i++) {
      final slide = draft.pages[i];
      final index = i + 1;
      final String subject = n == 1 ? "L'hinoo" : 'La pagina $index';
      final bg = slide.backgroundImage?.trim() ?? '';
      if (bg.isEmpty) {
        errors.add('$subject deve avere uno sfondo caricato.');
      }
      final text = slide.text.trim();
      if (text.isEmpty) {
        errors.add('$subject deve avere un testo.');
      }
    }
    return errors;
  }

  void _ensureLoggedIn() {
    final user = SupabaseProvider.client.auth.currentUser;
    if (user == null) throw 'Utente non autenticato';
  }

  String fingerprint(HinooDraft d) => HinooService.fingerprint(d);

  bool hasMeaningfulChanges(HinooDraft draft) =>
      fingerprint(draft) != lastSavedFingerprint;

  /// Caricamento sfondo a storage (builder chiama questo con i bytes scelti)
  Future<String> uploadBackgroundBytes(Uint8List bytes,
      {required String ext}) async {
    _ensureLoggedIn();
    final userId = SupabaseProvider.client.auth.currentUser!.id;
    return HinooStorageUploader.uploadBytes(
        bytes: bytes, filenameExt: ext, userId: userId);
  }

  /// Salvataggio nello scrigno (type personal/answer)
  Future<String> saveToChest(HinooDraft draft) async {
    _ensureLoggedIn();

    final errors = validateDraft(draft);
    if (errors.isNotEmpty) {
      throw 'Draft non valido:\n- ${errors.join('\n- ')}';
    }

    await HinooService.publishHinoo(draft);
    final fp = fingerprint(draft);
    lastSavedFingerprint = fp;
    return fp;
  }

  /// Pubblicazione su Luna (o already present)
  Future<HinooMoonResult> sendToMoon(HinooDraft draft) async {
    _ensureLoggedIn();

    final errors = validateDraft(draft);
    if (errors.isNotEmpty) {
      throw 'Draft non valido:\n- ${errors.join('\n- ')}';
    }

    final sanitized = draft.copyWith(type: HinooType.moon);
    final ok = await HinooService.duplicateToMoon(sanitized);
    return ok ? HinooMoonResult.published : HinooMoonResult.alreadyPresent;
  }

  /// (Opzionale) autosave bozza
  Future<void> saveDraft(HinooDraft draft) async {
    _ensureLoggedIn();
    await HinooService.saveDraft(draft);
  }

  /// Ripristina l'ultima bozza (o null)
  Future<HinooDraft?> getDraft() async {
    return HinooService.getDraft();
  }

  /// Carica un PNG esportato del canvas nel bucket hinoo/exports e ritorna l'URL pubblico.
  Future<String> uploadCanvasPng(Uint8List pngBytes) async {
    _ensureLoggedIn();
    final userId = SupabaseProvider.client.auth.currentUser!.id;
    return HinooStorageUploader.uploadExportPng(
      pngBytes: pngBytes,
      userId: userId,
    );
  }
}
