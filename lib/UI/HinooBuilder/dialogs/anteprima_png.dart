import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:honoo/Widgets/honoo_dialogs.dart';
import 'package:honoo/Widgets/loading_spinner.dart';

class AnteprimaPNG extends StatelessWidget {
  const AnteprimaPNG({
    super.key,
    required this.previewBytes,
    required this.filenameHint,
    required this.onSavePng,
    required this.onClose,
  });

  final Uint8List? previewBytes;
  final String? filenameHint;
  final Future<void> Function() onSavePng;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final Widget previewSection;
    if (previewBytes == null) {
      previewSection = const SizedBox(
        height: 200,
        child: Center(
          child: LoadingSpinner(
              color: Colors.white, semanticsLabel: 'Caricamento anteprima'),
        ),
      );
    } else {
      previewSection = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: Colors.black,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: FittedBox(
              fit: BoxFit.contain,
              child: Image.memory(previewBytes!),
            ),
          ),
        ),
      );
    }

    return HonooDialogShell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              filenameHint ?? 'Anteprima',
              style: HonooDialogStyles.title(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            previewSection,
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: previewBytes == null
                    ? null
                    : () async {
                        await onSavePng();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  disabledBackgroundColor: Colors.white10,
                  disabledForegroundColor: Colors.white38,
                ),
                child:
                    Text('Salva PNG', style: HonooDialogStyles.primaryAction()),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onClose,
              style: TextButton.styleFrom(foregroundColor: Colors.white54),
              child: Text('Chiudi', style: HonooDialogStyles.tertiaryAction()),
            ),
          ],
        ),
      ),
    );
  }
}
