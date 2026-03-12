import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:honoo/UI/HinooBuilder/services/download_saver.dart';
import 'package:honoo/Widgets/honoo_dialogs.dart';

Future<void> captureAndSave(BuildContext context, {
  required GlobalKey repaintKey,
  required String baseName,
  String toastOnStart = 'Download avviato.',
  String? message,
}) async {
  NavigatorState? rootNav;
  try {
    // Capture a navigator tied to a root overlay before any async gap
    rootNav = Navigator.of(context, rootNavigator: true);
    final RenderRepaintBoundary? boundary = repaintKey.currentContext
        ?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw Exception('Impossibile scaricare: boundary non trovata.');
    }

    double pixelRatio = 3.0;
    final ui.Size logicalSize = boundary.size;
    if (logicalSize.height > 0) {
      const double targetHeight = 1920.0;
      final double ratioH = targetHeight / logicalSize.height;
      if (ratioH.isFinite && ratioH > 0) pixelRatio = ratioH;
    }

    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData?.buffer.asUint8List();
    if (bytes == null || bytes.isEmpty) {
      throw Exception('PNG vuoto o nullo.');
    }

    final saver = getDownloadSaver();
    final String filename = '${baseName}_${DateTime.now().millisecondsSinceEpoch}.png';
    await saver.save([DownloadImage(filename: filename, bytes: bytes)]);

    if (!rootNav.mounted) return;
    showHonooToast(rootNav.context, message: message ?? toastOnStart);
  } catch (e) {
    if (rootNav != null && rootNav.mounted) {
      showHonooToast(rootNav.context, message: 'Errore download: $e');
    }
  }
}
