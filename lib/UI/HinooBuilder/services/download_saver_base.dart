import 'dart:typed_data';

abstract class DownloadSaver {
  Future<String> save(List<DownloadImage> images, {String? message});
}

class DownloadImage {
  DownloadImage({
    required this.filename,
    required this.bytes,
  });

  final String filename;
  final Uint8List bytes;
}
