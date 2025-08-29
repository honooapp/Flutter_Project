// lib/Utility/image_normalizer.dart
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Risultato della normalizzazione/squeeze dell’immagine
class NormalizedImage {
  final Uint8List bytes;
  final String ext; // 'jpg' | 'png' | 'webp'
  const NormalizedImage(this.bytes, this.ext);
}

/// Normalizza l’estensione in un set sicuro.
String sanitizeExt(String ext) {
  final e = ext.trim().toLowerCase();
  if (e == 'jpeg') return 'jpg';
  const allowed = {'jpg', 'png', 'webp'};
  return allowed.contains(e) ? e : 'jpg';
}

/// Se il file è molto grande (>10MB) o con estensione non ideale,
/// ricodifica a JPG qualità 88 e ridimensiona entro 1440x2560.
/// Altrimenti restituisce bytes+ext originali (ext sanificata).
Future<NormalizedImage> normalizeBackgroundImage(
    Uint8List rawBytes, {
      String originalExt = 'jpg',
      int maxUploadBytes = 10 * 1024 * 1024, // 10 MB
      int maxW = 1440,
      int maxH = 2560,
    }) async {
  final lower = sanitizeExt(originalExt);

  final shouldReencode =
      rawBytes.lengthInBytes > maxUploadBytes ||
          !(lower == 'jpg' || lower == 'png' || lower == 'webp');

  if (!shouldReencode) {
    return NormalizedImage(rawBytes, lower);
  }

  try {
    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) {
      return NormalizedImage(rawBytes, lower);
    }

    final oriented = img.bakeOrientation(decoded);

    final scaleW = maxW / oriented.width;
    final scaleH = maxH / oriented.height;
    final scale = (scaleW < scaleH) ? scaleW : scaleH;

    img.Image out = oriented;
    if (scale < 1.0) {
      final targetW = (oriented.width * scale).round();
      final targetH = (oriented.height * scale).round();
      out = img.copyResize(
        oriented,
        width: targetW,
        height: targetH,
        interpolation: img.Interpolation.linear,
      );
    }

    final jpg = Uint8List.fromList(img.encodeJpg(out, quality: 88));
    return NormalizedImage(jpg, 'jpg');
  } catch (_) {
    return NormalizedImage(rawBytes, lower);
  }
}
