import 'package:flutter/material.dart';
import 'package:honoo/UI/HinooBuilder/services/download_saver.dart';
import 'package:honoo/Widgets/honoo_dialogs.dart';

Future<void> showDownloadSaveResult({
  required BuildContext context,
  required String contentName,
  required DownloadSaveResult result,
}) async {
  // Sul web savedToGallery resta false anche quando il download o la
  // condivisione sono partiti correttamente. Arrivare qui significa che il
  // salvataggio si è concluso senza errori, quindi il feedback resta uniforme.
  final String subject = switch (contentName.toLowerCase()) {
    'campanello' => 'Il campanello',
    'honoo' => 'L’honoo',
    _ => 'L’hinoo',
  };
  await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => HonooConfirmDialog(
      title: '$subject è nella tua Galleria delle foto',
      confirmLabel: 'OK',
      showCancel: false,
    ),
  );
}
