import 'package:flutter/material.dart';
import 'package:honoo/Widgets/honoo_dialogs.dart';
import 'package:honoo/Widgets/loading_spinner.dart';

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
            const LoadingSpinner(size: 28, color: Colors.white),
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
