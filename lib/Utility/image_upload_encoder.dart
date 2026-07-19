import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class EncodedUploadImage {
  const EncodedUploadImage(this.bytes, this.extension);

  final Uint8List bytes;
  final String extension;
}

/// Decodes every format supported by the `image` package, applies the camera
/// orientation and produces a reasonably sized JPEG for Supabase Storage.
/// HEIC/HEIF must be converted by the platform-specific converter first.
Future<EncodedUploadImage> encodeImageForUpload(
  Uint8List source, {
  int maxLongEdge = 1920,
  int quality = 88,
}) async {
  final result = await compute<_EncodeRequest, List<Object>>(
    _encode,
    _EncodeRequest(source, maxLongEdge, quality),
  );
  return EncodedUploadImage(result[0] as Uint8List, result[1] as String);
}

class _EncodeRequest {
  const _EncodeRequest(this.bytes, this.maxLongEdge, this.quality);

  final Uint8List bytes;
  final int maxLongEdge;
  final int quality;
}

List<Object> _encode(_EncodeRequest request) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(request.bytes);
  } catch (_) {
    throw const FormatException('Formato immagine non riconosciuto');
  }
  if (decoded == null) {
    throw const FormatException('Formato immagine non riconosciuto');
  }

  decoded = img.bakeOrientation(decoded);
  final longEdge =
      decoded.width > decoded.height ? decoded.width : decoded.height;
  if (longEdge > request.maxLongEdge) {
    decoded = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? request.maxLongEdge : null,
      height: decoded.height > decoded.width ? request.maxLongEdge : null,
      interpolation: img.Interpolation.average,
    );
  }

  return <Object>[
    Uint8List.fromList(img.encodeJpg(decoded, quality: request.quality)),
    'jpg',
  ];
}
