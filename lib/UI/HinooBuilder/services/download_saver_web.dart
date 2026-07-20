// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_util' as js_util;

import 'download_saver_base.dart';

class _DownloadSaverWeb implements DownloadSaver {
  @override
  Future<String> save(List<DownloadImage> images, {String? message}) async {
    if (images.isEmpty) {
      return 'Nessuna immagine da scaricare.';
    }

    if (_isMobileOrTabletBrowser() && await _shareWithSystem(images, message)) {
      return images.length == 1
          ? 'Scegli “Salva immagine” per aggiungerla alla galleria.'
          : 'Scegli “Salva immagini” per aggiungerle alla galleria.';
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

bool _isMobileOrTabletBrowser() {
  return isMobileOrTabletBrowser(
    html.window.navigator.userAgent,
    maxTouchPoints: html.window.navigator.maxTouchPoints ?? 0,
  );
}

Future<bool> _shareWithSystem(
  List<DownloadImage> images,
  String? message,
) async {
  final html.Navigator navigator = html.window.navigator;
  if (!js_util.hasProperty(navigator, 'share')) return false;

  final List<html.File> files = images
      .map(
        (DownloadImage image) => html.File(
          <Object>[image.bytes],
          sanitizeDownloadFilename(image.filename),
          <String, dynamic>{'type': 'image/png'},
        ),
      )
      .toList(growable: false);
  final Object shareData = js_util.newObject();
  js_util.setProperty(shareData, 'files', files);
  js_util.setProperty(shareData, 'title', 'Honoo');
  if (message != null && message.trim().isNotEmpty) {
    js_util.setProperty(shareData, 'text', message.trim());
  }

  if (js_util.hasProperty(navigator, 'canShare')) {
    try {
      final bool canShare =
          js_util.callMethod<bool>(navigator, 'canShare', <Object>[shareData]);
      if (!canShare) return false;
    } catch (_) {
      return false;
    }
  }

  try {
    final Object promise =
        js_util.callMethod<Object>(navigator, 'share', <Object>[shareData]);
    await js_util.promiseToFuture<dynamic>(promise);
    return true;
  } catch (error) {
    // Un annullamento volontario non deve avviare un download inatteso.
    try {
      if (js_util.getProperty<String>(error, 'name') == 'AbortError') {
        return true;
      }
    } catch (_) {}
    return false;
  }
}

void _revokeLater(String url) {
  Timer(const Duration(seconds: 30), () => html.Url.revokeObjectUrl(url));
}
