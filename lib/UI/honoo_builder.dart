// lib/UI/honoo_builder.dart
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:honoo/Services/supabase_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../Services/honoo_image_uploader.dart';
import '../Utility/honoo_colors.dart';
import 'package:honoo/Widgets/centering_multiline_field.dart';
import 'package:honoo/UI/HinooBuilder/overlays/cambia_sfondo.dart';
import 'package:honoo/UI/HinooBuilder/services/download_saver.dart';
import 'package:honoo/Widgets/honoo_dialogs.dart';

class HonooBuilder extends StatefulWidget {
  final void Function(String text, String imageUrl)? onHonooChanged;
  final ValueChanged<bool>? onFocusChanged;
  final String? initialText;
  final String? imageHint;

  const HonooBuilder({
    super.key,
    this.onHonooChanged,
    this.onFocusChanged,
    this.initialText,
    this.imageHint,
  });

  @override
  State<HonooBuilder> createState() => HonooBuilderState();
}

class HonooBuilderState extends State<HonooBuilder> {
  static const double framePadding = 12.0;

  final TextEditingController _textCtrl = TextEditingController();
  final FocusNode _textFocus = FocusNode();

  // Anteprima immagine
  ImageProvider? imageProvider;

  // Controllo trasformazioni immagine
  final TransformationController _imageController = TransformationController();
  static const double _imageMinScale = 1.0;
  static const double _imageMaxScale = 5.0;
  double _imageScale = _imageMinScale;
  bool _imageConfirmed = false;

  bool get hasFocus => _textFocus.hasFocus;
  bool get hasImage => imageProvider != null;

  // URL pubblica finale caricata su Supabase (non-null per il callback)
  String _publicImageUrl = '';

  // Limiti testo
  final GlobalKey _imageBoundaryKey = GlobalKey(); // usata nel RepaintBoundary
  final GlobalKey _captureKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      _textCtrl.text = widget.initialText!;
    }
    _textCtrl.addListener(_emitChange);
    _imageController.addListener(_handleImageTransform);
    _textFocus.addListener(_handleFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onFocusChanged?.call(_textFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _textCtrl.removeListener(_emitChange);
    _textCtrl.dispose();
    _textFocus.removeListener(_handleFocusChange);
    _textFocus.dispose();
    _imageController.removeListener(_handleImageTransform);
    _imageController.dispose();
    super.dispose();
  }

  void _emitChange() {
    widget.onHonooChanged?.call(_textCtrl.text, _publicImageUrl);
  }

  void _handleFocusChange() {
    widget.onFocusChanged?.call(_textFocus.hasFocus);
    setState(() {});
  }

  void _confirmImage() {
    if (_imageConfirmed) return;
    setState(() {
      _imageConfirmed = true;
    });
    _emitChange();
  }

  void _handleImageTransform() {
    final double newScale = _extractScale(_imageController.value);
    if ((newScale - _imageScale).abs() > 0.005) {
      setState(() => _imageScale = newScale);
    }
  }

  double _extractScale(Matrix4 matrix) {
    final Float64List storage = matrix.storage;
    final double sx = storage[0].abs();
    final double sy = storage[5].abs();
    double raw;
    if (sx > 0 && sy > 0) {
      raw = (sx + sy) / 2;
    } else if (sx > 0) {
      raw = sx;
    } else if (sy > 0) {
      raw = sy;
    } else {
      raw = _imageMinScale;
    }
    return raw.clamp(_imageMinScale, _imageMaxScale).toDouble();
  }

  void _updateImageScale(double scale) {
    final double clamped =
        scale.clamp(_imageMinScale, _imageMaxScale).toDouble();
    final Matrix4 current = _imageController.value.clone();
    final Float64List values = current.storage;
    final double currentScale = _extractScale(current);
    final double safeScale = currentScale <= 0 ? _imageMinScale : currentScale;
    final double tx = values[12];
    final double ty = values[13];
    final double adjustedTx = tx * (safeScale / clamped);
    final double adjustedTy = ty * (safeScale / clamped);
    final Matrix4 updated = Matrix4.identity()
      ..translate(adjustedTx, adjustedTy)
      ..scale(clamped);
    _imageController.value = updated;
    setState(() => _imageScale = clamped);
  }

  void _nudgeImageScale(double delta) {
    _updateImageScale(_imageScale + delta);
  }

  void _resetImageTransform() {
    _imageController.value = Matrix4.identity();
    setState(() => _imageScale = _imageMinScale);
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final XFile? selected =
          await picker.pickImage(source: ImageSource.gallery);
      if (selected == null) return;

      // 0) Guardia autenticazione
      final client = SupabaseProvider.client;
      final session = client.auth.currentSession;
      if (session == null) {
        if (!mounted) return;
        showHonooToast(
          context,
          message: 'Devi essere loggato per caricare immagini.',
        );
        return;
      }
      // 1) Anteprima locale immediata (no blob:)
      final Uint8List bytes = await selected.readAsBytes();
      _imageController.value = Matrix4.identity();
      setState(() {
        imageProvider = MemoryImage(bytes);
        _imageScale = _imageMinScale;
        _imageConfirmed = false;
      });

      // 2) Path per‑utente: "<uid>/uploads/<file>"
      final sanitized = _sanitizeFileName(selected.name);
      final _ = '${DateTime.now().millisecondsSinceEpoch}_$sanitized';

// 3) Upload via service (usa i bytes letti sopra)
      final ext = _extensionFromName(selected.name); // ".png" / ".jpg" ecc.
      final publicUrl = await HonooImageUploader.uploadImageBytes(bytes, ext);

      if (publicUrl == null) {
        if (!mounted) return;
        showHonooToast(
          context,
          message: 'Upload fallito',
        );
        return;
      }

// 4) Salvo URL e notifico il parent
      setState(() {
        _publicImageUrl = publicUrl;
        // opzionale: verifica CDN
        // imageProvider = NetworkImage(_publicImageUrl);
      });
      _emitChange();
    } catch (e) {
      debugPrint('Errore selezione/upload immagine: $e');
      if (!mounted) return;
      showHonooToast(
        context,
        message: 'Errore immagine: $e',
      );
    }
  }

  String _extensionFromName(String name) {
    final n = name.toLowerCase();
    final i = n.lastIndexOf('.');
    if (i < 0) return '.jpg';
    final e = n.substring(i);
    if (e.length > 5) return '.jpg';
    return e;
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

        const double gap = 9.0;
        const double eps = 0.5;
        final double maxByH = (availH - gap - eps) / 1.5;
        final double imageSize = math.min(availW, maxByH);
        final double textHeight = imageSize / 2;
        final double totalHeight = textHeight + gap + imageSize;

        return Center(
          child: RepaintBoundary(
            key: _captureKey,
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
                    SizedBox(
                      width: imageSize,
                      height: textHeight,
                      child: _buildTextArea(imageSize),
                    ),
                    const SizedBox(height: gap),
                    SizedBox(
                      width: imageSize,
                      height: imageSize,
                      child: _buildImageArea(),
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

  Widget _buildTextArea(double imageSize) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Container(
            padding: EdgeInsets.zero,
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
            child: Builder(
              builder: (context) {
                final textStyle = GoogleFonts.arvo(
                  color: HonooColor.onTertiary,
                  fontSize: 18,
                  height: 1.4,
                );
                final double textMaxWidth = math.max(1, imageSize - 80);

                return CenteringMultilineField(
                  controller: _textCtrl,
                  focusNode: _textFocus,
                  style: textStyle,
                  horizontalPadding: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: InputDecoration(
                    hintText: 'Scrivi qui il testo del tuo honoo',
                    hintStyle: textStyle.copyWith(
                      color: HonooColor.background,
                      height: 1.2,
                    ),
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  expands: true,
                  scrollPhysics: const ClampingScrollPhysics(),
                  cursorColor: Colors.black,
                  cursorWidth: 3,
                  cursorRadius: const Radius.circular(0),
                  inputFormatters: [
                    _lineLimitFormatter(textMaxWidth, textStyle),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageArea() {
    return GestureDetector(
      onTap: _pickAndUploadImage,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Container(
          color: HonooColor.tertiary,
          child: imageProvider == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Carica qui la tua immagine',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.arvo(
                        color: HonooColor.background,
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
                    final double w = ivConstraints.maxWidth;
                    final double h = ivConstraints.maxHeight;

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        RepaintBoundary(
                          key: _imageBoundaryKey,
                          child: ClipRect(
                            child: InteractiveViewer(
                              transformationController: _imageController,
                              panEnabled: true,
                              scaleEnabled: true,
                              minScale: _imageMinScale,
                              maxScale: _imageMaxScale,
                              boundaryMargin: const EdgeInsets.all(200),
                              child: SizedBox(
                                width: w,
                                height: h,
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: Image(image: imageProvider!),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (!_imageConfirmed) ...[
                          CambiaSfondoOverlay(
                            onTapChange: _pickAndUploadImage,
                            showControls: true,
                            currentScale: _imageScale,
                            minScale: _imageMinScale,
                            maxScale: _imageMaxScale,
                            onScaleChanged: _updateImageScale,
                            onZoomIn: _imageScale < _imageMaxScale
                                ? () => _nudgeImageScale(0.1)
                                : null,
                            onZoomOut: _imageScale > _imageMinScale
                                ? () => _nudgeImageScale(-0.1)
                                : null,
                            onResetTransform: _resetImageTransform,
                          ),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: IconButton(
                              iconSize: 44,
                              onPressed: _confirmImage,
                              icon: SvgPicture.asset(
                                'assets/icons/ok.svg',
                                width: 44,
                                height: 44,
                              ),
                              tooltip: 'Conferma immagine',
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }

  static const int _honooMaxLines = 5;

  TextPainter _createHonooPainter(
    String text,
    double maxWidth,
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: null,
    )..layout(minWidth: 0, maxWidth: maxWidth);

    return painter;
  }

  int _countHonooLines(
    String text,
    double maxWidth,
    TextStyle style,
  ) {
    if (text.isEmpty) return 0;
    final painter = _createHonooPainter(text, maxWidth, style);
    final int autoCount = painter.computeLineMetrics().length;
    final int manualCount = text.split('\n').length;
    return math.max(autoCount, manualCount);
  }

  TextInputFormatter _lineLimitFormatter(
    double maxWidth,
    TextStyle style,
  ) {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      if (oldValue.text == newValue.text) return newValue;
      final count = _countHonooLines(newValue.text, maxWidth, style);
      if (count > _honooMaxLines) {
        return oldValue;
      }
      return newValue;
    });
  }

  void resetContent() {
    setState(() {
      _textCtrl.clear();
      imageProvider = null;
      _publicImageUrl = '';
      _imageController.value = Matrix4.identity();
      _imageScale = _imageMinScale;
      _imageConfirmed = false;
    });
    _emitChange();
    widget.onFocusChanged?.call(false);
  }

  Future<Uint8List?> _captureCurrentAsPng() async {
    final boundary = _captureKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;
    try {
      final double pixelRatio = View.of(context).devicePixelRatio;
      final ui.Image base = await boundary.toImage(pixelRatio: pixelRatio);
      final int framePx = (framePadding * pixelRatio).round();
      final int newWidth = base.width + framePx * 2;
      final int newHeight = base.height + framePx * 2;

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder,
          Rect.fromLTWH(0, 0, newWidth.toDouble(), newHeight.toDouble()));
      final Paint bgPaint = Paint()..color = HonooColor.background;
      canvas.drawRect(
          Rect.fromLTWH(0, 0, newWidth.toDouble(), newHeight.toDouble()),
          bgPaint);
      canvas.drawImage(
          base, Offset(framePx.toDouble(), framePx.toDouble()), Paint());
      final ui.Image framed =
          await recorder.endRecording().toImage(newWidth, newHeight);
      final ByteData? byteData =
          await framed.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Errore cattura honoo: $e');
      return null;
    }
  }

  Future<void> downloadHonooPublic(
    BuildContext context, {
    String? fileName,
  }) async {
    if (!hasImage) {
        showHonooToast(
          context,
          message: 'Per poter caricare l\'immagine, devi essere prima loggato',
        );
      return;
    }
    final Uint8List? bytes = await _captureCurrentAsPng();
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      showHonooToast(
        context,
        message: 'Impossibile generare il file PNG.',
      );
      return;
    }

    final saver = getDownloadSaver();
    final String fallbackName =
        'honoo_${DateTime.now().millisecondsSinceEpoch}';
    final String rawName = (fileName != null && fileName.trim().isNotEmpty)
        ? fileName.trim()
        : fallbackName;
    final String sanitizedInput = _sanitizeFileName(rawName);
    final bool hasContent = RegExp(r'[a-zA-Z0-9]').hasMatch(sanitizedInput);
    final String sanitized =
        hasContent ? sanitizedInput : _sanitizeFileName(fallbackName);
    final String filename =
        sanitized.toLowerCase().endsWith('.png') ? sanitized : '$sanitized.png';

    try {
      await saver.save([
        DownloadImage(filename: filename, bytes: bytes),
      ]);
      if (!mounted) return;
      showHonooToast(
        context,
        message: 'Download avviato: $filename',
      );
    } catch (e) {
      if (!mounted) return;
      showHonooToast(
        context,
        message: 'Errore durante il salvataggio: $e',
      );
    }
  }
}
