// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<Uint8List?> heicToPng(Uint8List input) async {
  try {
    // Richiede che la pagina includa heic2any:
    // <script src="https://unpkg.com/heic2any/dist/heic2any.min.js"></script>
    final JSFunction? heic2any = web.window.getProperty<JSFunction?>(
      'heic2any'.toJS,
    );
    if (heic2any == null) return null;

    final web.Blob blob = web.Blob(
      <JSAny>[input.toJS].toJS,
      web.BlobPropertyBag(type: 'image/heic'),
    );
    final JSObject params = JSObject()
      ..setProperty('blob'.toJS, blob)
      ..setProperty('toType'.toJS, 'image/png'.toJS);
    final JSPromise<JSAny?> promise =
        heic2any.callAsFunction(null, params) as JSPromise<JSAny?>;
    final JSAny? pngBlob = await promise.toDart;
    if (pngBlob == null) return null;
    final JSArrayBuffer buffer = await (pngBlob as web.Blob)
        .arrayBuffer()
        .toDart;
    return buffer.toDart.asUint8List();
  } catch (_) {
    return null;
  }
}
