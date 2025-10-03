import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HonooDialogStyles {
  static TextStyle title() => GoogleFonts.lora(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      );

  static TextStyle body({Color color = Colors.white70}) => GoogleFonts.lora(
        color: color,
        fontSize: 14,
      );

  static TextStyle caption({Color color = Colors.white70}) => GoogleFonts.lora(
        color: color,
        fontSize: 12,
      );

  static TextStyle primaryAction() => GoogleFonts.lora(
        color: Colors.black,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      );

  static TextStyle secondaryAction() => GoogleFonts.lora(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      );

  static TextStyle tertiaryAction({Color color = Colors.white54}) => GoogleFonts.lora(
        color: color,
        fontSize: 13,
      );
}

class HonooDialogShell extends StatelessWidget {
  const HonooDialogShell({
    super.key,
    required this.child,
    this.opacity = 0.92,
    this.maxWidth = 420,
  });

  final Widget child;
  final double opacity;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black.withOpacity(opacity),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class HonooConfirmDialog extends StatelessWidget {
  const HonooConfirmDialog({
    super.key,
    required this.title,
    this.message,
    required this.confirmLabel,
    this.cancelLabel = 'Annulla',
  });

  final String title;
  final String? message;
  final String confirmLabel;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    return HonooDialogShell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: HonooDialogStyles.title(), textAlign: TextAlign.center),
            if (message != null && message!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                message!,
                style: HonooDialogStyles.body(),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(confirmLabel, style: HonooDialogStyles.primaryAction()),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(foregroundColor: Colors.white54),
              child: Text(cancelLabel, style: HonooDialogStyles.tertiaryAction()),
            ),
          ],
        ),
      ),
    );
  }
}

enum HonooDeletionTarget { page, honoo, hinoo }

Future<bool?> showHonooDeleteDialog(
  BuildContext context, {
  required HonooDeletionTarget target,
  String? message,
  bool barrierDismissible = true,
}) {
  final String title;
  switch (target) {
    case HonooDeletionTarget.page:
      title = 'Vuoi davvero eliminare questa pagina?';
      break;
    case HonooDeletionTarget.honoo:
      title = 'Vuoi davvero eliminare questo honoo?';
      break;
    case HonooDeletionTarget.hinoo:
      title = 'Vuoi davvero eliminare questo hinoo?';
      break;
  }

  final String body = message ?? 'L’operazione non è reversibile.';

  return showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (_) => HonooConfirmDialog(
      title: title,
      message: body,
      confirmLabel: 'Elimina',
    ),
  );
}
