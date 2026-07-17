import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../UI/HinooBuilder/services/download_saver.dart';

typedef DownloadSaverFactory = DownloadSaver Function();
typedef DownloadTimestampFactory = int Function();

class DownloadCaptureService {
  DownloadCaptureService({
    DownloadSaverFactory? saverFactory,
    DownloadTimestampFactory? timestampFactory,
  })  : _saverFactory = saverFactory ?? getDownloadSaver,
        _timestampFactory =
            timestampFactory ?? (() => DateTime.now().millisecondsSinceEpoch);

  final DownloadSaverFactory _saverFactory;
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

  Future<String> captureAndSave({
    required GlobalKey repaintKey,
    required String baseName,
    String? message,
  }) async {
    final boundary =
        repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw Exception('Impossibile scaricare: boundary non trovata.');
    }

    final image = await boundary.toImage(
      pixelRatio: pixelRatioForHeight(boundary.size.height),
    );
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();
      if (bytes == null || bytes.isEmpty) {
        throw Exception('PNG vuoto o nullo.');
      }

      final filename = '${baseName}_${_timestampFactory()}.png';
      return _saverFactory().save(
        [DownloadImage(filename: filename, bytes: bytes)],
        message: message,
      );
    } finally {
      image.dispose();
    }
  }
}
