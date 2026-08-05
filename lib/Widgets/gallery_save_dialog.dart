import 'package:flutter/material.dart';
import 'package:honoo/UI/HinooBuilder/services/download_saver.dart';
import 'package:honoo/Widgets/honoo_dialogs.dart';

Future<void> showDownloadSaveResult({
  required BuildContext context,
  required String contentName,
  required Future<bool> Function(DownloadSaveResult result) openSavedImage,
  required DownloadSaveResult result,
}) async {
  if (!result.savedToGallery) {
    if (result.message.isNotEmpty) {
      showHonooToast(context, message: result.message);
    }
    return;
  }

  final bool? openGallery = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => HonooConfirmDialog(
      title:
          'L’$contentName è stato salvato\n'
          'nella tua Galleria delle Foto',
      confirmLabel: 'Apri galleria',
      cancelLabel: 'Ignora',
    ),
  );
  if (openGallery != true || !context.mounted) return;

  final bool opened = await openSavedImage(result);
  if (!opened && context.mounted) {
    showHonooToast(context, message: 'Impossibile aprire l’immagine salvata.');
  }
}
