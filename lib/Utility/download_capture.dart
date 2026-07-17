import 'package:flutter/material.dart';
import 'package:honoo/Services/download_capture_service.dart';
import 'package:honoo/Widgets/honoo_dialogs.dart';

final DownloadCaptureService _downloadCaptureService = DownloadCaptureService();

Future<void> captureAndSave(
  BuildContext context, {
  required GlobalKey repaintKey,
  required String baseName,
  String toastOnStart = 'Download avviato.',
  String? message,
}) async {
  NavigatorState? rootNav;
  try {
    // Capture a navigator tied to a root overlay before any async gap
    rootNav = Navigator.of(context, rootNavigator: true);
    await _downloadCaptureService.captureAndSave(
      repaintKey: repaintKey,
      baseName: baseName,
    );

    if (!rootNav.mounted) return;
    showHonooToast(rootNav.context, message: message ?? toastOnStart);
  } catch (e) {
    if (rootNav != null && rootNav.mounted) {
      showHonooToast(rootNav.context, message: 'Errore download: $e');
    }
  }
}
