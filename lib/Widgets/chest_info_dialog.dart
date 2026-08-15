import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../Utility/honoo_colors.dart';
import 'honoo_dialogs.dart';

const chestInfoTextBeforeIcons =
    "Questo è il tuo Scrigno\n\n"
    "Qui sono custoditi\n"
    "gli honoo e gli hinoo\n"
    "che hai scritto,\n\n"
    "quelli che hai salvato dalla Luna,\n\n"
    "e quelli che hai ricevuto\n\n";

const chestInfoTextAfterIcons =
    "Scorri verso destra\n"
    "per rivedere ciò che hai scritto\n"
    "e ciò che hai salvato\n\n"
    "Scorri dall’alto verso il basso\n"
    "per seguire\n"
    "le conversazioni\n\n"
    "In alto\n"
    "l’honoo della Luna\n\n"
    "Sopra\n"
    "la tua risposta\n\n"
    "E, sopra ancora,\n"
    "se arriva,\n"
    "la risposta\n"
    "alla tua risposta\n";

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
        final maxWidth = (constraints.maxWidth * 0.8).clamp(
          0.0,
          constraints.maxWidth,
        );
        final maxHeight = (constraints.maxHeight * 0.8).clamp(
          0.0,
          constraints.maxHeight,
        );
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
                        child: Text.rich(
                          TextSpan(
                            style: HonooDialogStyles.body(
                              color: HonooColor.onBackground,
                            ),
                            children: [
                              const TextSpan(text: chestInfoTextBeforeIcons),
                              _chestIconSpan(
                                asset: 'assets/icons/honoo_chest_blue.svg',
                                semanticsLabel: 'Blu',
                                size: _responsiveIconSize(maxWidth),
                              ),
                              const TextSpan(text: '\nsono i tuoi\n\n'),
                              _chestIconSpan(
                                asset: 'assets/icons/honoo_chest_white.svg',
                                semanticsLabel: 'Bianchi',
                                size: _responsiveIconSize(maxWidth),
                              ),
                              const TextSpan(text: '\nquelli della Luna\n\n'),
                              _chestIconSpan(
                                asset: 'assets/icons/honoo_chest_red.svg',
                                semanticsLabel: 'Rossi',
                                size: _responsiveIconSize(maxWidth),
                              ),
                              const TextSpan(
                                text:
                                    '\nquelli che ti sono stati inviati\n\n'
                                    '$chestInfoTextAfterIcons',
                              ),
                            ],
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
                    icon: SvgPicture.asset(
                      'assets/icons/cancella.svg',
                      width: 40,
                      height: 40,
                      colorFilter: const ColorFilter.mode(
                        HonooColor.onBackground,
                        BlendMode.srcIn,
                      ),
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

  static double _responsiveIconSize(double availableWidth) =>
      (availableWidth * 0.2).clamp(44.0, 72.0);

  static WidgetSpan _chestIconSpan({
    required String asset,
    required String semanticsLabel,
    required double size,
  }) => WidgetSpan(
    alignment: PlaceholderAlignment.middle,
    child: Semantics(
      image: true,
      label: semanticsLabel,
      child: SvgPicture.asset(
        asset,
        width: size,
        height: size,
        excludeFromSemantics: true,
      ),
    ),
  );
}
