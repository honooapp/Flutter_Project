import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/UI/HinooBuilder/services/download_saver_base.dart';

void main() {
  group('sanitizeDownloadFilename', () {
    test('mantiene un nome portabile', () {
      expect(sanitizeDownloadFilename('37.1.png'), '37.1.png');
    });

    test('rimuove separatori e caratteri non validi', () {
      expect(
        sanitizeDownloadFilename(' il/mio:hinoo?*.PNG '),
        'il_mio_hinoo__.png',
      );
    });

    test('usa un fallback quando il nome non contiene caratteri validi', () {
      expect(sanitizeDownloadFilename('... .png'), 'honoo.png');
    });
  });

  group('isMobileOrTabletBrowser', () {
    test('riconosce telefoni e tablet Android', () {
      expect(
        isMobileOrTabletBrowser('Mozilla/5.0 (Linux; Android 14; Pixel 8)'),
        isTrue,
      );
      expect(
        isMobileOrTabletBrowser('Mozilla/5.0 (Linux; Android 13; SM-X700)'),
        isTrue,
      );
    });

    test('riconosce iPhone, iPad e iPad con user agent desktop', () {
      expect(
        isMobileOrTabletBrowser('Mozilla/5.0 (iPhone; CPU iPhone OS 17_0)'),
        isTrue,
      );
      expect(
        isMobileOrTabletBrowser('Mozilla/5.0 (iPad; CPU OS 17_0)'),
        isTrue,
      );
      expect(
        isMobileOrTabletBrowser(
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15)',
          maxTouchPoints: 5,
        ),
        isTrue,
      );
    });

    test('non modifica il comportamento desktop', () {
      expect(
        isMobileOrTabletBrowser(
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15)',
        ),
        isFalse,
      );
      expect(
        isMobileOrTabletBrowser('Mozilla/5.0 (Windows NT 10.0; Win64; x64)'),
        isFalse,
      );
    });
  });
}
