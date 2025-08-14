import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../Utility/HonooColors.dart';

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
  static const int _capacity = _perLine * _maxLines; // 155

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

        final double availH = (rawH - media.padding.vertical - media.viewInsets.bottom)
            .clamp(0.0, double.infinity);

        if (availW <= 0 || availH <= 0) {
          return const SizedBox.shrink();
        }

        // Parametri di layout
        const double gap = 9.0;    // spazio tra box testo e immagine
        const double eps = 2.0;    // cuscinetto anti-rounding
        const double counterLift = 12.0; // quanto “sale” il contatore sopra il bordo bianco

        // Altezza totale = image/2 + gap + image = 1.5*image + gap
        // Vincolo in altezza → image <= (availH - gap - eps) / 1.5
        final double maxByH = (availH - gap - eps) / 1.5;

        // Lato del quadrato immagine limitato da larghezza e altezza
        double imageSize = math.min(availW, maxByH);

        // Arrotonda verso il basso per evitare sforamenti di 1–2 px
        imageSize = imageSize.isFinite ? imageSize.floorToDouble() : 0.0;

        final double textHeight = (imageSize / 2).floorToDouble();
        final double totalHeight = (textHeight + gap + imageSize).floorToDouble();

        // UI
        return Center(
          child: Card(
            color: HonooColor.background,
            elevation: 0,
            margin: EdgeInsets.zero,
            clipBehavior: Clip.hardEdge,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            child: SizedBox(
              width: imageSize,     // larghezza blocco = lato del quadrato
              height: totalHeight,  // 1.5 × lato + gap
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ======== SEZIONE TESTO ========
                  SizedBox(
                    width: imageSize,
                    height: textHeight,
                    child: Stack(
                      clipBehavior: Clip.none, // consente al contatore di “uscire” sopra al box
                      children: [
                        // Contatore in alto a destra, FUORI dal box bianco
                        Positioned(
                          right: 0,
                          top: -counterLift, // spostato verso l’alto
                          child: SizedBox(
                            child: ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _textCtrl,
                              builder: (context, value, _) {
                                final rem = (_capacity - value.text.length)
                                    .clamp(0, _capacity);
                                return Text(
                                  '$rem',
                                  style: GoogleFonts.arvo(
                                    color: HonooColor.onBackground,
                                    fontSize: 10,
                                  ),
                                );
                              },
                            ),
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
                            child: Center( // centro perfetto (orizzontale + verticale)
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: imageSize,
                                  maxHeight: textHeight,
                                ),
                                child: ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: _textCtrl,
                                  builder: (context, value, _) {
                                    // Hint visibile solo quando vuoto
                                    final String? hint = value.text.isEmpty
                                        ? 'Scrivi qui il tuo testo'
                                        : null;

                                    return TextField(
                                      controller: _textCtrl,
                                      textAlign: TextAlign.center,                 // centro orizzontale
                                      textAlignVertical: TextAlignVertical.center, // centro verticale
                                      minLines: _maxLines,
                                      maxLines: _maxLines,
                                      keyboardType: TextInputType.multiline,
                                      inputFormatters: const [
                                        VisibleSpaceFormatter(
                                          maxLines: _maxLines,
                                          maxLineLength: _perLine,
                                        ),
                                      ],
                                      decoration: InputDecoration(
                                        hintText: hint,
                                        hintStyle: GoogleFonts.arvo(
                                          color: HonooColor.onTertiary.withOpacity(0.6),
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
                        final selected = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
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
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: HonooColor.tertiary,
                            image: imageProvider != null
                                ? DecorationImage(
                              image: imageProvider!,
                              fit: BoxFit.cover,
                            )
                                : null,
                          ),
                          child: imageProvider == null
                              ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Carica qui la tua immagine',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.arvo(
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
                              : Align(
                            alignment: Alignment.bottomCenter,
                            child: IconButton(
                              icon: const Icon(Icons.delete),
                              color: HonooColor.onBackground,
                              onPressed: () {
                                setState(() {
                                  image = null;
                                  imageProvider = null;
                                });
                                _emitChange();
                              },
                            ),
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
