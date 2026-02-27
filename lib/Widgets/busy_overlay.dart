import 'package:flutter/material.dart';
import 'package:honoo/Widgets/honoo_dialogs.dart';

class BusyOverlay extends StatelessWidget {
  const BusyOverlay({super.key, this.message = 'Attendi...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return HonooDialogShell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
