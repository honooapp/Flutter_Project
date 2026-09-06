import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'text_box_download_button.dart';

/// Keeps the original canvas size. Short viewports scroll instead of scaling
/// the content down to make room for editing actions.
class ContentEditFrame extends StatelessWidget {
  const ContentEditFrame({
    super.key,
    required this.child,
    required this.width,
    required this.height,
    required this.onImage,
    required this.onText,
    this.onSave,
  });
  final Widget child;
  final double width;
  final double height;
  final VoidCallback onImage;
  final VoidCallback onText;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final viewportHeight = constraints.maxHeight.isFinite
          ? constraints.maxHeight
          : height + 40;
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: viewportHeight),
          child: Center(
            child: SizedBox(
              width: math.min(width, constraints.maxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextBoxDownloadButton(
                          key: const Key('content-edit-image'),
                          onPressed: onImage,
                          tooltip: 'Modifica immagine',
                          asset: 'assets/icons/immagine.svg',
                        ),
                        if (onSave != null)
                          TextBoxDownloadButton(
                            onPressed: onSave!,
                            tooltip: 'Conferma e salva',
                            asset: 'assets/icons/ok.svg',
                          ),
                        TextBoxDownloadButton(
                          key: const Key('content-edit-text'),
                          onPressed: onText,
                          tooltip: 'Modifica testo',
                          asset: 'assets/icons/modifica testo.svg',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: width, height: height, child: child),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
