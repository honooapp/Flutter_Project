// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'download_saver_base.dart';

class _DownloadSaverWeb implements DownloadSaver {
  @override
  Future<String> save(List<DownloadImage> images, {String? message}) async {
    if (images.isEmpty) {
      return 'Nessuna immagine da scaricare.';
    }

    for (final DownloadImage img in images) {
      final html.Blob blob = html.Blob(<dynamic>[img.bytes], 'image/png');
      final String url = html.Url.createObjectUrlFromBlob(blob);
      final html.AnchorElement anchor = html.AnchorElement(href: url)
        ..download = img.filename
        ..style.display = 'none';
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
    }

    return images.length == 1 ? 'Download avviato.' : 'Download multipli avviati.';
  }
}

DownloadSaver getDownloadSaverImpl() => _DownloadSaverWeb();
