import 'dart:typed_data';

/// Stub per piattaforme non-web: non fa alcuna conversione.
/// Ritorna sempre null per indicare "nessuna conversione eseguita".
Future<Uint8List?> convertHeicToWebSafe(Uint8List bytes, String filename) async {
  return null;
}

