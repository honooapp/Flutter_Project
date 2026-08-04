import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../UI/HinooBuilder/services/download_saver.dart';
import '../Widgets/text_box_download_button.dart';

typedef DownloadSaverFactory = DownloadSaver Function();
typedef DownloadTimestampFactory = int Function();

class DownloadCaptureService {
  DownloadCaptureService({
    DownloadSaverFactory? saverFactory,
    DownloadTimestampFactory? timestampFactory,
  }) : _saver = (saverFactory ?? getDownloadSaver)(),
       _timestampFactory =
           timestampFactory ?? (() => DateTime.now().millisecondsSinceEpoch);

  final DownloadSaver _saver;
  final DownloadTimestampFactory _timestampFactory;

  static double pixelRatioForHeight(
    double logicalHeight, {
    double targetHeight = 1920,
    double fallback = 3,
  }) {
    if (logicalHeight <= 0) return fallback;
    final ratio = targetHeight / logicalHeight;
    return ratio.isFinite && ratio > 0 ? ratio : fallback;
  }

  Future<DownloadSaveResult> captureAndSave({
    required GlobalKey repaintKey,
    required String baseName,
    String? message,
  }) async {
    final boundary =
        repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw Exception('Impossibile scaricare: boundary non trovata.');
    }

    final bytes = await TextBoxDownloadButton.hideWhileCapturing(() async {
      final image = await boundary.toImage(
        pixelRatio: pixelRatioForHeight(boundary.size.height),
      );
      try {
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final bytes = byteData?.buffer.asUint8List();
        if (bytes == null || bytes.isEmpty) {
          throw Exception('PNG vuoto o nullo.');
        }
        return bytes;
      } finally {
        image.dispose();
      }
    });

    final filename = '${baseName}_${_timestampFactory()}.png';
    return _saver.save([
      DownloadImage(filename: filename, bytes: bytes),
    ], message: message);
  }

  Future<bool> openSavedImage(DownloadSaveResult result) =>
      _saver.openSavedImage(result);
}
