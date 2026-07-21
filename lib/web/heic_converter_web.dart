// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Converte un file HEIC in un formato web-safe (preferibilmente WEBP, fallback PNG).
/// Ritorna i bytes convertiti oppure null se non è HEIC o se non è possibile convertire.
Future<Uint8List?> convertHeicToWebSafe(
  Uint8List bytes,
  String filename,
) async {
  try {
    final bool looksHeic = _isHeicByName(filename) || _isHeicByHeader(bytes);
    if (!looksHeic) return null; // Non HEIC → nessuna conversione

    // heic2any è caricato in window tramite <script src="...heic2any.min.js"></script>
    final JSFunction? heic2any = web.window.getProperty<JSFunction?>(
      'heic2any'.toJS,
    );
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
    final String brand = String.fromCharCodes(
      bytes.sublist(8, 12),
    ).toLowerCase();
    return brand.startsWith('hei') || brand.startsWith('hev');
  } catch (_) {
    return false;
  }
}

Future<Uint8List?> _tryConvert(
  Uint8List input,
  JSFunction heic2any,
  String toMime,
) async {
  try {
    final web.Blob blob = web.Blob(
      <JSAny>[input.toJS].toJS,
      web.BlobPropertyBag(type: 'image/heic'),
    );
    final JSObject params = JSObject()
      ..setProperty('blob'.toJS, blob)
      ..setProperty('toType'.toJS, toMime.toJS);
    final JSPromise<JSAny?> promise =
        heic2any.callAsFunction(null, params) as JSPromise<JSAny?>;
    final JSAny? outBlob = await promise.toDart;
    if (outBlob == null) return null;
    final JSArrayBuffer buffer = await (outBlob as web.Blob)
        .arrayBuffer()
        .toDart;
    return buffer.toDart.asUint8List();
  } catch (_) {
    // ignora, proveremo fallback o restituiremo null
  }
  return null;
}
