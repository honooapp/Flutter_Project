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

    final bool iosSafari = _isIosSafari();
    for (final DownloadImage img in images) {
      // Alcuni browser mobile (iOS Safari) ignorano download programmatici.
      // Usiamo un fallback aprendolo in una nuova scheda.
      final String mime = iosSafari ? 'application/octet-stream' : 'image/png';
      final html.Blob blob = html.Blob(<dynamic>[img.bytes], mime);
      final String url = html.Url.createObjectUrlFromBlob(blob);

      try {
        if (iosSafari) {
          // Fallback: apri in una nuova scheda; l’utente può salvare dall’UI
          html.window.open(url, '_blank');
          // Ritarda la revoca per dare tempo al browser di consumare l’URL
          await Future<void>.delayed(const Duration(milliseconds: 200));
          html.Url.revokeObjectUrl(url);
        } else {
          final html.AnchorElement anchor = html.AnchorElement(href: url)
            ..download = img.filename
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
        html.window.open(url, '_blank');
        await Future<void>.delayed(const Duration(milliseconds: 200));
        html.Url.revokeObjectUrl(url);
      }
    }

    return images.length == 1
        ? 'Download avviato.'
        : 'Download multipli avviati.';
  }
}

DownloadSaver getDownloadSaverImpl() => _DownloadSaverWeb();

bool _isIosSafari() {
  final ua = html.window.navigator.userAgent.toLowerCase();
  final bool isIOS = ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod');
  final bool isSafari = ua.contains('safari') &&
      !ua.contains('crios') && // Chrome iOS
      !ua.contains('fxios') && // Firefox iOS
      !ua.contains('edgios'); // Edge iOS
  return isIOS && isSafari;
}
