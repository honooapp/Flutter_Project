import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Widgets/loading_spinner.dart';

class CambiaSfondoOverlay extends StatelessWidget {
  const CambiaSfondoOverlay({
    super.key,
    required this.onTapChange,
    this.promptText,
    this.showControls = false,
    this.isUploading = false,
    this.currentScale = 1.0,
    this.minScale = 1.0,
    this.maxScale = 5.0,
    this.onScaleChanged,
    this.onZoomIn,
    this.onZoomOut,
    this.onResetTransform,
    this.useCompactControls = false,
  });

  final VoidCallback onTapChange;
  final String? promptText;
  final bool showControls;
  final bool isUploading;
  final double currentScale;
  final double minScale;
  final double maxScale;
  final ValueChanged<double>? onScaleChanged;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onResetTransform;
  final bool useCompactControls;

  @override
  Widget build(BuildContext context) {
    if (!showControls) {
      return Align(
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: onTapChange,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.50),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  promptText ??
                      'Carica prima la tua immagine,\n e poi scrivi il tuo testo',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lora(color: Colors.white, fontSize: 17),
                ),
                const SizedBox(height: 22),
                SvgPicture.asset(
                  'assets/icons/immagine.svg',
                  width: 48,
                  height: 48,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final double clampedScale = currentScale
        .clamp(minScale, maxScale)
        .toDouble();
    final int computedDivisions = ((maxScale - minScale) * 10).round();
    final int? sliderDivisions = computedDivisions > 0
        ? computedDivisions
        : null;

    if (!useCompactControls) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              key: const Key('hinoo-image-editing-controls'),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Trascina per spostare l’immagine\n'
                    'Usa il pizzico o i controlli per zoomare',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lora(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  IgnorePointer(
                    ignoring: isUploading,
                    child: Opacity(
                      opacity: isUploading ? 0.6 : 1,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: Colors.white,
                          overlayColor: Colors.white24,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: onZoomOut,
                              icon: const Icon(Icons.remove),
                              color: Colors.white,
                              tooltip: 'Riduci zoom',
                            ),
                            Expanded(
                              child: Slider(
                                value: clampedScale,
                                min: minScale,
                                max: maxScale,
                                divisions: sliderDivisions,
                                label: '${clampedScale.toStringAsFixed(1)}x',
                                onChanged: onScaleChanged,
                              ),
                            ),
                            IconButton(
                              onPressed: onZoomIn,
                              icon: const Icon(Icons.add),
                              color: Colors.white,
                              tooltip: 'Aumenta zoom',
                            ),
                            if (onResetTransform != null)
                              IconButton(
                                onPressed: onResetTransform,
                                icon: const Icon(
                                  Icons.center_focus_strong_outlined,
                                ),
                                color: Colors.white,
                                tooltip: 'Reimposta posizione',
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Zoom: ${clampedScale.toStringAsFixed(1)}x',
                    style: GoogleFonts.lora(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  if (isUploading) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const LoadingSpinner(size: 18, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          'Caricamento immagine…',
                          style: GoogleFonts.lora(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: onTapChange,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      icon: SvgPicture.asset(
                        'assets/icons/immagine.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      label: const Text('Sostituisci immagine'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 10,
          left: 18,
          right: 18,
          child: IgnorePointer(
            ignoring: isUploading,
            child: Opacity(
              opacity: isUploading ? 0.6 : 1,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  activeTrackColor: HonooColor.background,
                  inactiveTrackColor: HonooColor.background.withValues(
                    alpha: 0.28,
                  ),
                  thumbColor: Colors.white,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 7,
                  ),
                  overlayColor: Colors.white.withValues(alpha: 0.18),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                ),
                child: Slider(
                  key: const Key('hinoo-image-zoom-slider'),
                  value: clampedScale,
                  min: minScale,
                  max: maxScale,
                  divisions: sliderDivisions,
                  onChanged: onScaleChanged,
                ),
              ),
            ),
          ),
        ),
        if (isUploading)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LoadingSpinner(size: 18, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    'Caricamento immagine…',
                    style: GoogleFonts.lora(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
