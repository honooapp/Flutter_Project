import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'honoo_dialogs.dart';

class HouseRequestSentDialog extends StatelessWidget {
  const HouseRequestSentDialog({super.key, required this.email});
  final String email;

  @override
  Widget build(BuildContext context) => HonooDialogShell(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Richiesta inviata', style: HonooDialogStyles.title()),
            const SizedBox(height: 12),
            Text(
              email.isNotEmpty
                  ? '$email ha richiesto una casa sull\'Isola.'
                  : 'Hai richiesto una casa sull\'Isola.',
              style: HonooDialogStyles.body(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: _primaryStyle(),
                child: Text('OK', style: _actionStyle()),
              ),
            ),
          ]),
        ),
      );
}

class HouseRequestReceivedDialog extends StatelessWidget {
  const HouseRequestReceivedDialog({super.key, required this.email});
  final String email;

  @override
  Widget build(BuildContext context) => HonooDialogShell(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Richiesta ricevuta', style: HonooDialogStyles.title()),
            const SizedBox(height: 12),
            Text(
              email.isNotEmpty
                  ? '$email ha richiesto una casa sull\'Isola.'
                  : 'Un utente ha richiesto una casa sull\'Isola.',
              style: HonooDialogStyles.body(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Non ora',
                      style: HonooDialogStyles.secondaryAction()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: _primaryStyle(),
                  child: Text('Invita', style: _actionStyle()),
                ),
              ),
            ]),
          ]),
        ),
      );
}

ButtonStyle _primaryStyle() => ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
    );

TextStyle _actionStyle() =>
    GoogleFonts.libreFranklin(fontWeight: FontWeight.w700);
