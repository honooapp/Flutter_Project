import 'package:flutter/material.dart';
import 'package:honoo/Widgets/honoo_dialogs.dart';
import 'package:honoo/Widgets/loading_spinner.dart';

enum DownloadChoice { firstOnly, allPages }

class DownloadHinooDialog extends StatelessWidget {
  const DownloadHinooDialog({
    super.key,
    required this.pageCount,
  });

  final int pageCount;

  @override
  Widget build(BuildContext context) {
    final bool multiplePages = pageCount > 1;
    final String bodyText = multiplePages
        ? 'Scegli se scaricare questa versione o tutte le pagine disponibili.'
        : 'Scarica il tuo hinoo in formato .png.';

    return HonooDialogShell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Scarica hinoo',
                style: HonooDialogStyles.title(), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(bodyText,
                style: HonooDialogStyles.body(), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pop(DownloadChoice.firstOnly),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(multiplePages ? 'Scarica questa versione' : 'Scarica',
                    style: HonooDialogStyles.primaryAction()),
              ),
            ),
            if (multiplePages) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).pop(DownloadChoice.allPages),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Scarica tutte le pagine',
                      style: HonooDialogStyles.secondaryAction()),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.white54),
              child: Text('Annulla', style: HonooDialogStyles.tertiaryAction()),
            ),
          ],
        ),
      ),
    );
  }
}

class DownloadProgressDialog extends StatelessWidget {
  const DownloadProgressDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return HonooDialogShell(
      opacity: 0.88,
      maxWidth: 320,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LoadingSpinner(
              size: 48,
              color: Colors.white,
              semanticsLabel: 'Preparazione download',
            ),
            const SizedBox(height: 16),
            Text(
              'Preparazione download…',
              style: HonooDialogStyles.body(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
