import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../Utility/HonooColors.dart';
import '../Utility/LineLengthLimitingTextInputFormatter.dart';

class HonooBuilder extends StatefulWidget {
  final void Function(String text, String imagePath)? onHonooChanged;

  const HonooBuilder({super.key, this.onHonooChanged});

  @override
  State<HonooBuilder> createState() => _HonooBuilderState();
}

class _HonooBuilderState extends State<HonooBuilder> {
  XFile? image;
  final TextEditingController _textCtrl = TextEditingController();
  ImageProvider<Object>? imageProvider;

  void _emitChange() {
    if (widget.onHonooChanged != null && image != null) {
      widget.onHonooChanged!.call(_textCtrl.text, image!.path);
    } else if (widget.onHonooChanged != null) {
      widget.onHonooChanged!.call(_textCtrl.text, '');
    }
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
        // Spazio realmente disponibile dal parent (in tempo reale)
        final double availW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : media.size.width;

        final double availHBase = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : media.size.height;

        // Togli safe area + tastiera (phone)
        final double availH = (availHBase
            - media.padding.vertical
            - media.viewInsets.bottom)
            .clamp(0.0, double.infinity);

        // Lato del quadrato immagine: non deve superare la larghezza né l'altezza/1.5
        // (perché l'altezza totale = image + image/2 = 1.5 * image)
        const double epsilon = 1.0; // piccolo cuscinetto anti-rounding
        final double imageSize = math.min(availW, (availH - epsilon) / 1.5)
            .clamp(40.0, double.infinity);

        final double textWidth = imageSize;         // stessa larghezza del quadrato
        final double textHeight = imageSize / 2;    // metà del quadrato
        final double totalHeight = textHeight + imageSize;

        // FittedBox garantisce nessun overflow al resize (scala in tempo reale)
        return Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: imageSize,
              height: totalHeight,
              child: Card(
                color: HonooColor.background,
                elevation: 0,
                margin: EdgeInsets.zero,
                clipBehavior: Clip.hardEdge,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // BOX TESTO: stessa larghezza del quadrato, altezza = metà
                    SizedBox(
                      width: textWidth,
                      height: textHeight,
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
                        child: Column(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _textCtrl,
                                textAlign: TextAlign.center,
                                expands: true,      // riempie il box; niente salti
                                maxLines: null,
                                minLines: null,
                                keyboardType: TextInputType.multiline,
                                inputFormatters: [
                                  LineLengthLimitingTextInputFormatter(
                                    maxLineLength: 31,
                                    maxLines: 100,
                                  ),
                                ],
                                decoration: const InputDecoration(
                                  hintText: 'Scrivi qui il tuo testo',
                                  border: InputBorder.none,
                                  isCollapsed: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: GoogleFonts.arvo(
                                  color: HonooColor.onTertiary,
                                  fontSize: 16,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${144 - _textCtrl.text.length}',
                              style: GoogleFonts.arvo(
                                color: HonooColor.onTertiary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // IMMAGINE QUADRATA SOTTO
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
                          child: Container(
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
          ),
        );
      },
    );
  }
}
