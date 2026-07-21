import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../Utility/honoo_colors.dart';
import 'honoo_dialogs.dart';

const chestInfoText = "Questo è il tuo Scrigno.\n\n"
    "Qui sono custoditi\n"
    "gli honoo e gli hinoo\n"
    "che hai scritto,\n\n"
    "quelli che hai salvato dalla Luna,\n\n"
    "e quelli che hai ricevuto.\n\n"
    "Blu\n"
    "sono i tuoi.\n\n"
    "Bianco\n"
    "quelli della Luna.\n\n"
    "Rosso\n"
    "quelli che ti sono stati inviati.\n\n"
    "Scorri verso destra\n"
    "per rivedere ciò che hai scritto\n"
    "e ciò che hai salvato.\n\n"
    "Scorri dall’alto verso il basso\n"
    "per seguire\n"
    "le conversazioni.\n\n"
    "In alto\n"
    "l’honoo della Luna.\n\n"
    "Sotto\n"
    "la tua risposta.\n\n"
    "E, sotto ancora,\n"
    "se arriva,\n"
    "la risposta\n"
    "alla tua risposta.\n";

Future<void> showChestInfoDialog(BuildContext context) => showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const ChestInfoDialog(),
    );

class ChestInfoDialog extends StatelessWidget {
  const ChestInfoDialog({super.key});

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth =
                (constraints.maxWidth * 0.8).clamp(0.0, constraints.maxWidth);
            final maxHeight =
                (constraints.maxHeight * 0.8).clamp(0.0, constraints.maxHeight);
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  maxHeight: maxHeight,
                ),
                child: Stack(
                  children: [
                    ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: maxWidth,
                          height: maxHeight,
                          padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                          decoration: BoxDecoration(
                            color: HonooColor.wave1.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Text(
                              chestInfoText,
                              style: HonooDialogStyles.body(
                                color: HonooColor.onBackground,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: HonooColor.onBackground,
                        ),
                        iconSize: 40,
                        tooltip: 'Chiudi',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
}
