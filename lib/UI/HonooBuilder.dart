// lib/UI/HonooBuilder.dart
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Utility/HonooColors.dart';
import 'dart:ui' as ui;

/// Limita testo a X righe e Y caratteri per riga
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
    final lines = rawLines.take(maxLines).toList();
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].length > maxLineLength) {
        lines[i] = lines[i].substring(0, maxLineLength);
      }
    }
    final clipped = lines.join('\n');
    if (clipped == newValue.text) return newValue;

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
  final void Function(String text, String imageUrl)? onHonooChanged;

  const HonooBuilder({super.key, this.onHonooChanged});

  @override
  State<HonooBuilder> createState() => _HonooBuilderState();
}

class _HonooBuilderState extends State<HonooBuilder> {
  final TextEditingController _textCtrl = TextEditingController();

  // Anteprima immagine
  ImageProvider? imageProvider;

  // URL pubblica finale caricata su Supabase (non-null per il callback)
  String _publicImageUrl = '';

  // Bucket pubblico su Supabase
  static const String _bucketName = 'honoo-images';

  // Limiti testo
  static const int _perLine = 32;
  static const int _maxLines = 5;
  static const int _capacity = 144;

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

  void _emitChange() {
    widget.onHonooChanged?.call(_textCtrl.text, _publicImageUrl);
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final XFile? selected = await picker.pickImage(source: ImageSource.gallery);
      if (selected == null) return;

      // 1) Bytes per anteprima e upload (Web/iOS/Android)
      final Uint8List bytes = await selected.readAsBytes();

      // 2) Anteprima immediata (nessun blob:)
      setState(() {
        imageProvider = MemoryImage(bytes);
      });

      // 3) Upload su Supabase Storage (bucket pubblico)
      final client = Supabase.instance.client;
      final sanitized = _sanitizeFileName(selected.name);
      final filename = '${DateTime.now().millisecondsSinceEpoch}_$sanitized';
      final storagePath = 'uploads/$filename';

      await client.storage.from(_bucketName).uploadBinary(
        storagePath,
        bytes,
        fileOptions: FileOptions(
          upsert: false,
          contentType: _guessContentType(selected.name),
        ),
      );

      // 4) Public URL HTTPS
      final publicUrl = client.storage.from(_bucketName).getPublicUrl(storagePath);

      // 5) Notifica il parent SOLO con URL pubblica https
      setState(() => _publicImageUrl = publicUrl);
      _emitChange();
    } catch (e) {
      debugPrint('Errore selezione/upload immagine: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore immagine: $e')),
      );
    }
  }

  String _guessContentType(String name) {
    final ext = name.toLowerCase();
    if (ext.endsWith('.png')) return 'image/png';
    if (ext.endsWith('.webp')) return 'image/webp';
    if (ext.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  String _sanitizeFileName(String name) {
    // rimuove spazi e caratteri strani dal nome file
    return name.replaceAll(RegExp(r'[^a-zA-Z0-9\.\-_]'), '_');
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availW =
        constraints.maxWidth.isFinite ? constraints.maxWidth : media.size.width;

        final double rawH =
        constraints.maxHeight.isFinite ? constraints.maxHeight : media.size.height;

        final double availH =
        (rawH - media.padding.vertical - media.viewInsets.bottom)
            .clamp(0.0, double.infinity);

        if (availW <= 0 || availH <= 0) {
          return const SizedBox.shrink();
        }

        // layout: text box alto metà dell’immagine, sotto immagine quadrata
        const double gap = 9.0;
        const double eps = 0.5;

        final double maxByH = (availH - gap - eps) / 1.5;
        final double imageSize = math.min(availW, maxByH);
        final double textHeight = imageSize / 2;
        final double totalHeight = textHeight + gap + imageSize;

        // helper per il colore in base ai caratteri residui
        Color _counterColor(int remaining) {
          if (remaining <= 12) return HonooColor.secondary; // rosso
          return HonooColor.onBackground; // bianco
        }

        return Center(
          child: Card(
            color: HonooColor.background,
            elevation: 0,
            margin: EdgeInsets.zero,
            clipBehavior: Clip.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            child: SizedBox(
              width: imageSize,
              height: totalHeight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ======== BOX TESTO ========
                  SizedBox(
                    width: imageSize,
                    height: textHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Contatore in alto a destra
                        Positioned(
                          right: 5,
                          top: -counterLift,
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
                        // Area di testo
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
                            child: ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _textCtrl,
                              builder: (context, value, _) {
                                final String? hint = value.text.isEmpty
                                    ? 'Scrivi qui il tuo testo'
                                    : null;

                                return TextField(
                                  controller: _textCtrl,
                                  textAlign: TextAlign.center,
                                  textAlignVertical: TextAlignVertical.center,
                                  expands: true,
                                  minLines: null,
                                  maxLines: null,
                                  keyboardType: TextInputType.multiline,
                                  inputFormatters: const [
                                    VisibleSpaceFormatter(
                                      maxLines: _maxLines,
                                      maxLineLength: _perLine,
                                    ),
                                  ],
                                  decoration: InputDecoration(
                                    hintText: hint,
                                    hintStyle: GoogleFonts.libreFranklin(
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
                      ],
                    ),
                  ),

                  const SizedBox(height: gap),

                  // ======== BOX IMMAGINE (quadrata) ========
                  SizedBox(
                    width: imageSize,
                    height: imageSize,
                    child: GestureDetector(
                      onTap: _pickAndUploadImage,
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

                              // Copertura garantita a scala 1.0
                              const _ivMinScale = 1.0;
                              const _ivMaxScale = 5.0;

                              return Stack(
                                children: [
                                  // Catturiamo esattamente la cornice
                                  RepaintBoundary(
                                    key: _imageBoundaryKey,
                                    child: ClipRect(
                                      child: InteractiveViewer(
                                        panEnabled: true,
                                        scaleEnabled: true,
                                        minScale: _ivMinScale,
                                        maxScale: _ivMaxScale,
                                        boundaryMargin:
                                        const EdgeInsets.all(200),
                                        child: SizedBox(
                                          width: w,
                                          height: h,
                                          child: FittedBox(
                                            fit: BoxFit.cover,
                                            child: Image(
                                              image: imageProvider!,
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
