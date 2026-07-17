import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Services/download_capture_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DownloadCaptureService', () {
    test('calcola il rapporto necessario per raggiungere 1920 px', () {
      expect(DownloadCaptureService.pixelRatioForHeight(640), 3);
      expect(DownloadCaptureService.pixelRatioForHeight(960), 2);
    });

    test('usa il rapporto di fallback per altezze non valide', () {
      expect(DownloadCaptureService.pixelRatioForHeight(0), 3);
      expect(DownloadCaptureService.pixelRatioForHeight(-1), 3);
    });

    test('segnala una boundary mancante prima di invocare il saver', () async {
      final service = DownloadCaptureService();

      expect(
        () => service.captureAndSave(
          repaintKey: GlobalKey(),
          baseName: 'honoo',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
