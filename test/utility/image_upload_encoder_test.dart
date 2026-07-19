import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Utility/image_upload_encoder.dart';
import 'package:image/image.dart' as img;

void main() {
  test('normalizza e ridimensiona immagini grandi per Storage', () async {
    final source = img.Image(width: 2400, height: 1200);
    img.fill(source, color: img.ColorRgb8(120, 80, 40));

    final encoded = await encodeImageForUpload(
      img.encodePng(source),
      maxLongEdge: 600,
    );
    final decoded = img.decodeImage(encoded.bytes);

    expect(encoded.extension, 'jpg');
    expect(decoded, isNotNull);
    expect(decoded!.width, 600);
    expect(decoded.height, 300);
  });

  test('rifiuta contenuti che non sono immagini', () async {
    expect(
      encodeImageForUpload(Uint8List.fromList(<int>[1, 2, 3])),
      throwsA(isA<FormatException>()),
    );
  });
}
