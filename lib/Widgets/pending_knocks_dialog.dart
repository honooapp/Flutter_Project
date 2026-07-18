import 'package:flutter/material.dart';

import '../Entities/pending_knock.dart';
import 'honoo_dialogs.dart';

class PendingKnocksDialog extends StatelessWidget {
  const PendingKnocksDialog({
    super.key,
    required this.knocks,
    required this.labelForKnock,
    required this.timestampForKnock,
    required this.onOpen,
  });

  final List<PendingKnock> knocks;
  final String Function(PendingKnock knock) labelForKnock;
  final String Function(PendingKnock knock) timestampForKnock;
  final Future<void> Function(PendingKnock knock) onOpen;

  Future<void> _open(BuildContext context, PendingKnock knock) async {
    Navigator.of(context).pop();
    await onOpen(knock);
  }

  @override
  Widget build(BuildContext context) {
    return HonooDialogShell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bussate in attesa',
              style: HonooDialogStyles.title(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final knock in knocks)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _open(context, knock),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  labelForKnock(knock),
                                  style: HonooDialogStyles.primaryAction(),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () => _open(context, knock),
                                  child: Text(
                                    timestampForKnock(knock),
                                    style: HonooDialogStyles.tertiaryAction(),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.white54),
              child: Text(
                'Chiudi',
                style: HonooDialogStyles.tertiaryAction(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
