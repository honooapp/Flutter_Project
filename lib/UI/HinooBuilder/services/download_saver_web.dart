// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';

import 'download_saver_base.dart';

class _DownloadSaverWeb implements DownloadSaver {
  @override
  Future<String> save(List<DownloadImage> images, {String? message}) async {
    if (images.isEmpty) {
      return 'Nessuna immagine da scaricare.';
    }

    final bool iosBrowser = _isIosBrowser();
    for (final DownloadImage img in images) {
      // Alcuni browser mobile (iOS Safari) ignorano download programmatici.
      // Usiamo un fallback aprendolo in una nuova scheda.
      final String mime = iosBrowser ? 'application/octet-stream' : 'image/png';
      final html.Blob blob = html.Blob(<dynamic>[img.bytes], mime);
      final String url = html.Url.createObjectUrlFromBlob(blob);

      try {
        if (iosBrowser) {
          // Fallback: apri in una nuova scheda; l’utente può salvare dall’UI
          final dynamic opened = html.window.open(url, '_blank');
          if (opened == null) {
            html.window.location.assign(url);
          } else {
            _revokeLater(url);
          }
        } else {
          final html.AnchorElement anchor = html.AnchorElement(href: url)
            ..download = sanitizeDownloadFilename(img.filename)
            ..rel = 'noopener'
            ..target = '_self'
            ..style.display = 'none';
          html.document.body?.append(anchor);
          anchor.click();
          anchor.remove();
          html.Url.revokeObjectUrl(url);
        }
      } catch (_) {
        // Ultimo fallback generico: prova ad aprire in nuova scheda
        final dynamic opened = html.window.open(url, '_blank');
        if (opened == null) {
          html.window.location.assign(url);
        } else {
          _revokeLater(url);
        }
      }
    }

    return images.length == 1
        ? 'Download avviato.'
        : 'Download multipli avviati.';
  }
}

DownloadSaver getDownloadSaverImpl() => _DownloadSaverWeb();

bool _isIosBrowser() {
  final ua = html.window.navigator.userAgent.toLowerCase();
  return ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod');
}

void _revokeLater(String url) {
  Timer(const Duration(seconds: 30), () => html.Url.revokeObjectUrl(url));
}
