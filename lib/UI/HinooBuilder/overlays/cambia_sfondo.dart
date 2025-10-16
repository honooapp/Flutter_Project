import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CambiaSfondoOverlay extends StatelessWidget {
  const CambiaSfondoOverlay({
    super.key,
    required this.onTapChange,
    this.showControls = false,
    this.isUploading = false,
    this.currentScale = 1.0,
    this.minScale = 1.0,
    this.maxScale = 5.0,
    this.onScaleChanged,
    this.onZoomIn,
    this.onZoomOut,
    this.onResetTransform,
  });

  final VoidCallback onTapChange;
  final bool showControls;
  final bool isUploading;
  final double currentScale;
  final double minScale;
  final double maxScale;
  final ValueChanged<double>? onScaleChanged;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onResetTransform;

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
              color: Colors.black.withOpacity(0.50),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Carica prima la tua immagine,\n e poi scrivi il tuo testo',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lora(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 22),
                const Icon(
                  Icons.photo,
                  size: 48,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final double clampedScale =
        currentScale.clamp(minScale, maxScale).toDouble();
    final int computedDivisions = ((maxScale - minScale) * 10).round();
    final int? sliderDivisions =
        computedDivisions > 0 ? computedDivisions : null;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Trascina per spostare lo sfondo.\nUsa il pizzico o i controlli per zoomare.',
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
                          IconButton(
                            onPressed: onResetTransform,
                            icon: const Icon(Icons.center_focus_strong_outlined),
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
                  style: GoogleFonts.lora(color: Colors.white70, fontSize: 12),
                ),
                if (isUploading) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Caricamento sfondo…',
                        style:
                            GoogleFonts.lora(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: onTapChange,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Sostituisci sfondo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
