import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../Utility/HonooColors.dart';
import 'dart:ui' as ui;

/// Formatter che impedisce di superare lo spazio visibile:
/// - maxLines righe
/// - maxLineLength caratteri per riga
class VisibleSpaceFormatter extends TextInputFormatter {
  final int maxLines;
  final int maxLineLength;

  const VisibleSpaceFormatter({
    required this.maxLines,
    required this.maxLineLength,
  });

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final rawLines = newValue.text.split('\n');

    // Taglia numero righe
    final lines = rawLines.take(maxLines).toList();

    // Taglia ogni riga alla lunghezza max
    for (int i = 0; i < lines.length; i++) {
      final l = lines[i];
      if (l.length > maxLineLength) {
        lines[i] = l.substring(0, maxLineLength);
      }
    }

    final clipped = lines.join('\n');

    if (clipped == newValue.text) {
      return newValue; // nessuna modifica → non toccare il cursore
    }

    // Ricompatta la selection
    final base = newValue.selection.baseOffset;
    final newOffset = math.min(clipped.length, math.max(0, base));
    return TextEditingValue(
      text: clipped,
      selection: TextSelection.collapsed(offset: newOffset),
      composing: TextRange.empty,
    );
  }
}

class HonooBuilder extends StatefulWidget {
  final void Function(String text, String imagePath)? onHonooChanged;

  const HonooBuilder({super.key, this.onHonooChanged});

  @override
  State<HonooBuilder> createState() => _HonooBuilderState();
}

class _HonooBuilderState extends State<HonooBuilder> {
  XFile? image;
  ImageProvider<Object>? imageProvider;
  final TextEditingController _textCtrl = TextEditingController();

  static const int _perLine = 31;
  static const int _maxLines = 5;
  static const int _capacity = 144; // 144

  void _emitChange() {
    final cb = widget.onHonooChanged;
    if (cb == null) return;
    cb(_textCtrl.text, image?.path ?? '');
  }

  @override
  void initState() {
    super.initState();
    _textCtrl.addListener(_emitChange);
  }

  @override
  void dispose() {
    _textCtrl.removeListener(_emitChange);
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Spazio disponibile (live), togliendo safe area + tastiera
        final double availW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : media.size.width;

        final double rawH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : media.size.height;

        final double availH =
        (rawH - media.padding.vertical - media.viewInsets.bottom)
            .clamp(0.0, double.infinity);

        if (availW <= 0 || availH <= 0) {
          return const SizedBox.shrink();
        }

        // Parametri di layout
        const double gap = 9.0; // spazio tra box testo e immagine (lasciato com'era)
        const double eps = 2.0; // cuscinetto anti-rounding
        const double counterLift =
        22.0; // quanto “sale” il contatore sopra il bordo bianco

        // Altezza totale = image/2 + gap + image = 1.5*image + gap
        // Vincolo in altezza → image <= (availH - gap - eps) / 1.5
        final double maxByH = (availH - gap - eps) / 1.5;

        // Lato del quadrato immagine limitato da larghezza e altezza
        double imageSize = math.min(availW, maxByH);

        // Arrotonda verso il basso per evitare sforamenti di 1–2 px
        imageSize = imageSize.isFinite ? imageSize.floorToDouble() : 0.0;

        final double textHeight = (imageSize / 2).floorToDouble();
        final double totalHeight =
        (textHeight + gap + imageSize).floorToDouble();

        // helper per il colore in base ai caratteri residui
        Color _counterColor(int remaining) {
          if (remaining <= 12) return HonooColor.secondary; // rosso
          return HonooColor.onBackground; // bianco
        }

        final GlobalKey _imageBoundaryKey = GlobalKey(); // per catturare la cornice

        double _ivMinScale = 1.0;    // min scale calcolato a runtime in base al box
        double _ivMaxScale = 5.0;    // quanto vuoi permettere di zoommare

        Future<Uint8List?> _captureCroppedSquarePng() async {
          try {
            final boundary = _imageBoundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
            if (boundary == null) return null;

            // Pixel ratio alto per buona qualità (usa devicePixelRatio)
            final pixelRatio = ui.window.devicePixelRatio;
            final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
            final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
            return byteData?.buffer.asUint8List();
          } catch (_) {
            return null;
          }
        }


        // UI
        return Center(
          child: Card(
            color: HonooColor.background,
            elevation: 0,
            margin: EdgeInsets.zero,
            clipBehavior: Clip
                .none, // ⬅️ lascia “uscire” il contatore fuori dalla cornice bianca
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            child: SizedBox(
              width: imageSize, // larghezza blocco = lato del quadrato
              height: totalHeight, // 1.5 × lato + gap
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ======== SEZIONE TESTO ========
                  SizedBox(
                    width: imageSize,
                    height: textHeight,
                    child: Stack(
                      clipBehavior: Clip
                          .none, // consente al contatore di “uscire” sopra al box
                      children: [
                        // ✅ Contatore in alto a destra, FUORI dal box bianco
                        Positioned(
                          right: 5,
                          top: -counterLift, // negativo => fuori dalla cornice
                          child: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _textCtrl,
                            builder: (context, value, _) {
                              final int remaining =
                              (_capacity - value.text.length)
                                  .clamp(0, _capacity);
                              return Text(
                                '$remaining',
                                style: GoogleFonts.libreFranklin(
                                  color: _counterColor(remaining),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                        ),

                        // Box di testo (bianco)
                        Positioned.fill(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: HonooColor.tertiary,
                              border: Border.all(color: Colors.black12),
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            // TextField che RIEMPIE il box e centra verticalmente hint+testo
                            child: ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _textCtrl,
                              builder: (context, value, _) {
                                final String? hint = value.text.isEmpty
                                    ? 'Scrivi qui il tuo testo'
                                    : null;

                                return TextField(
                                  controller: _textCtrl,
                                  textAlign: TextAlign.center, // centro orizzontale
                                  textAlignVertical: TextAlignVertical
                                      .center, // centro verticale
                                  expands:
                                  true, // riempie tutto il box bianco
                                  minLines: null,
                                  maxLines: null,
                                  keyboardType: TextInputType.multiline,
                                  inputFormatters: const [
                                    VisibleSpaceFormatter(
                                      maxLines: _maxLines, // 5
                                      maxLineLength: _perLine, // 31
                                    ),
                                  ],
                                  decoration: InputDecoration(
                                    hintText: hint, // scompare appena scrivi
                                    hintStyle: GoogleFonts.libreFranklin(
                                      color: HonooColor.onTertiary
                                          .withOpacity(0.6),
                                      fontSize: 18,
                                      height: 1.2,
                                    ),
                                    border: InputBorder.none,
                                    isCollapsed: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: GoogleFonts.arvo(
                                    color: HonooColor.onTertiary,
                                    fontSize: 18,
                                    height: 1.4,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // GAP tra i due box
                  const SizedBox(height: gap),

                  // ======== SEZIONE IMMAGINE (quadrata) ========
                  SizedBox(
                    width: imageSize,
                    height: imageSize,
                    child: GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final selected = await picker.pickImage(source: ImageSource.gallery);
                        if (selected != null) {
                          setState(() {
                            image = selected;
                            imageProvider = kIsWeb
                                ? NetworkImage(image!.path)
                                : FileImage(File(image!.path)) as ImageProvider<Object>;
                          });
                          _emitChange();
                        }
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Container(
                          color: HonooColor.tertiary,
                          child: (imageProvider == null)
                              ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Carica qui la tua immagine',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.libreFranklin(
                                  color: HonooColor.onSecondary,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 22),
                              const Icon(
                                Icons.photo,
                                size: 48,
                                color: HonooColor.primary,
                              ),
                            ],
                          )
                              : LayoutBuilder(
                            builder: (context, ivConstraints) {
                              final w = ivConstraints.maxWidth;
                              final h = ivConstraints.maxHeight;

                              // Calcola minScale per coprire sempre la cornice (cover)
                              // assumendo che l’immagine abbia un layout “intrinseco” ≈ al box.
                              // InteractiveViewer parte da scale=1.0 sul child, quindi minScale = 1.0 copre sempre.
                              _ivMinScale = 1.0;

                              return Stack(
                                children: [
                                  // Catturiamo esattamente la cornice (per eventuale "conferma")
                                  RepaintBoundary(
                                    key: _imageBoundaryKey,
                                    child: ClipRect( // importantissimo per ritaglio pulito
                                      child: InteractiveViewer(
                                        panEnabled: true,
                                        scaleEnabled: true,
                                        minScale: _ivMinScale,
                                        maxScale: _ivMaxScale,
                                        boundaryMargin: const EdgeInsets.all(200), // consente panning oltre i bordi
                                        child: SizedBox(
                                          width: w,
                                          height: h,
                                          child: FittedBox(
                                            fit: BoxFit.cover, // copre sempre il riquadro
                                            child: Image(
                                              image: imageProvider!,
                                              // Manteniamo alta risoluzione “fonte” nel FittedBox
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
