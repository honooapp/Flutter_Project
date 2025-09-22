import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum DownloadChoice { firstOnly, allPages }

class DownloadHinooDialog extends StatelessWidget {
  const DownloadHinooDialog({
    super.key,
    required this.pageCount,
  });

  final int pageCount;

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle = GoogleFonts.lora(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    );
    final TextStyle bodyStyle = GoogleFonts.lora(
      color: Colors.white70,
      fontSize: 14,
    );
    final TextStyle buttonStyle = GoogleFonts.lora(
      color: Colors.black,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );
    final TextStyle outlinedStyle = GoogleFonts.lora(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );
    final String bodyText = pageCount > 1
        ? 'Scegli se scaricare solo la prima schermata o tutte le $pageCount schermate.'
        : 'Scarica la schermata in formato PNG.';

    return Dialog(
      backgroundColor: Colors.black.withOpacity(0.92),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Scarica hinoo', style: titleStyle, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(bodyText, style: bodyStyle, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(DownloadChoice.firstOnly),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text('Solo la prima schermata', style: buttonStyle),
              ),
            ),
            if (pageCount > 1) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(DownloadChoice.allPages),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Tutte le schermate', style: outlinedStyle),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.white54),
              child: Text('Annulla', style: GoogleFonts.lora(fontSize: 13)),
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
    return Dialog(
      backgroundColor: Colors.black.withOpacity(0.88),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 48,
              width: 48,
              child: CircularProgressIndicator(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Preparazione download…',
              style: GoogleFonts.lora(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

