import 'package:flutter/material.dart';

import '../Entities/knock_message_choice.dart';
import 'honoo_dialogs.dart';

class KnockMessageDialog extends StatelessWidget {
  const KnockMessageDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return HonooDialogShell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Vuoi inviare un messaggio\nprima di bussare?',
              style: HonooDialogStyles.title(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pop(KnockMessageChoice.hinoo),
                style: _primaryStyle(),
                child: Text(
                  'Scrivi un hinoo',
                  style: HonooDialogStyles.primaryAction(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pop(KnockMessageChoice.honoo),
                style: _primaryStyle(),
                child: Text(
                  'Scrivi un honoo',
                  style: HonooDialogStyles.primaryAction(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(KnockMessageChoice.none),
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
              child: Text(
                'No, bussa e basta',
                style: HonooDialogStyles.tertiaryAction(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _primaryStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
    );
  }
}
