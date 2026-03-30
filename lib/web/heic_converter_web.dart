// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:js_util' as js_util;

/// Converte un file HEIC in un formato web-safe (preferibilmente WEBP, fallback PNG).
/// Ritorna i bytes convertiti oppure null se non è HEIC o se non è possibile convertire.
Future<Uint8List?> convertHeicToWebSafe(Uint8List bytes, String filename) async {
  try {
    final bool looksHeic = _isHeicByName(filename) || _isHeicByHeader(bytes);
    if (!looksHeic) return null; // Non HEIC → nessuna conversione

    // heic2any è caricato in window tramite <script src="...heic2any.min.js"></script>
    final dynamic heic2any = js_util.getProperty(html.window, 'heic2any');
    if (heic2any == null) {
      // Script non disponibile → segnala HEIC non supportato
      return null;
    }

    // Prova WEBP
    final Uint8List? webp = await _tryConvert(bytes, heic2any, 'image/webp');
    if (webp != null && webp.isNotEmpty) return webp;

    // Fallback PNG
    final Uint8List? png = await _tryConvert(bytes, heic2any, 'image/png');
    if (png != null && png.isNotEmpty) return png;

    return null; // Conversione fallita
  } catch (_) {
    // Non propagare eccezioni: ritorna null per lasciare al chiamante la gestione
    return null;
  }
}

bool _isHeicByName(String name) {
  final n = name.toLowerCase().trim();
  return n.endsWith('.heic') || n.endsWith('.heif');
}

bool _isHeicByHeader(Uint8List bytes) {
  // HEIC è un ISOBMFF (mp4/quicktime) con brand 'heic', 'heif', 'hevc', 'hevx'
  // Tipicamente i primi 12 byte contengono: offset 4-7: 'ftyp', 8-11: brand
  if (bytes.length < 12) return false;
  try {
    final String box = String.fromCharCodes(bytes.sublist(4, 8));
    if (box != 'ftyp') return false;
    final String brand = String.fromCharCodes(bytes.sublist(8, 12)).toLowerCase();
    return brand.startsWith('hei') || brand.startsWith('hev');
  } catch (_) {
    return false;
  }
}

Future<Uint8List?> _tryConvert(Uint8List input, dynamic heic2any, String toMime) async {
  try {
    final html.Blob blob = html.Blob(<dynamic>[input], 'image/heic');
    final params = js_util.jsify(<String, dynamic>{
      'blob': blob,
      'toType': toMime,
    });
    final dynamic promise = js_util.callMethod(heic2any, 'call', [null, params]);
    final dynamic outBlob = await js_util.promiseToFuture(promise);
    if (outBlob is html.Blob) {
      final reader = html.FileReader();
      final completer = Completer<Uint8List?>();
      reader.onLoadEnd.listen((_) {
        final result = reader.result;
        if (result is ByteBuffer) {
          completer.complete(result.asUint8List());
        } else if (result is Uint8List) {
          completer.complete(result);
        } else {
          completer.complete(null);
        }
      });
      reader.onError.listen((_) => completer.complete(null));
      reader.readAsArrayBuffer(outBlob);
      return await completer.future;
    }
  } catch (_) {
    // ignora, proveremo fallback o restituiremo null
  }
  return null;
}

