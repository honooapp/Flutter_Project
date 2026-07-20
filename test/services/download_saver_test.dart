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
}
