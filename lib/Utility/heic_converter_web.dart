// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:typed_data';
import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as jsu;

Future<Uint8List?> heicToPng(Uint8List input) async {
  try {
    // Richiede che la pagina includa heic2any:
    // <script src="https://unpkg.com/heic2any/dist/heic2any.min.js"></script>
    final heic2any = jsu.getProperty(html.window, 'heic2any');
    if (heic2any == null) return null;

    final blob = html.Blob([input], 'image/heic');
    final params = jsu.jsify({'blob': blob, 'toType': 'image/png'});
    final promise = jsu.callMethod(heic2any, 'call', [null, params]);
    final dynamic pngBlob = await jsu.promiseToFuture(promise);
    if (pngBlob == null) return null;

    // Leggi il Blob in Uint8List
    final reader = html.FileReader();
    final c = Completer<Uint8List?>();
    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (result is ByteBuffer) {
        c.complete(result.asUint8List());
      } else if (result is Uint8List) {
        c.complete(result);
      } else {
        c.complete(null);
      }
    });
    reader.onError.listen((_) => c.complete(null));
    reader.readAsArrayBuffer(pngBlob as html.Blob);
    return await c.future;
  } catch (_) {
    return null;
  }
}
