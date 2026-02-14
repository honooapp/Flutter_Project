// lib/UI/honoo_builder.dart
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:honoo/Services/supabase_provider.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Widgets/honoo_dialogs.dart';
import 'package:honoo/UI/HinooBuilder/services/download_saver.dart';
import 'package:honoo/Widgets/width_limited_multiline_field.dart';
import 'package:honoo/Widgets/text_box_download_button.dart';

import '../Pages/email_login_page.dart';
import '../Services/honoo_image_uploader.dart';
import '../UI/HinooBuilder/overlays/cambia_sfondo.dart';

class HonooBuilder extends StatefulWidget {
  static const double baselineImageSize = 360.0;
  static const double baselineGap = 9.0;
  static const double baselineTextHeight = baselineImageSize / 2;
  static const double baselineTotalHeight =
      baselineImageSize + baselineGap + baselineTextHeight;

  final void Function(String text, String imageUrl)? onHonooChanged;
  final ValueChanged<bool>? onFocusChanged;
  final String? initialText;
  final String? imageHint;
  final VoidCallback? onDownloadTap;
  final bool showDownloadButton;

  const HonooBuilder({
    super.key,
    this.onHonooChanged,
    this.onFocusChanged,
    this.initialText,
    this.imageHint,
    this.onDownloadTap,
    this.showDownloadButton = true,
  });

  @override
  State<HonooBuilder> createState() => HonooBuilderState();
}

class HonooBuilderState extends State<HonooBuilder> {
  static const double framePadding = 12.0;

  final TextEditingController _textCtrl = TextEditingController();
  final FocusNode _textFocus = FocusNode();

  Uint8List? _imageBytes;

  // preview zoommata “confermata”
  Uint8List? _confirmedPreviewBytes;

  // trasformazioni zoom/pan
  final TransformationController _imageController = TransformationController();
  static const double _imageMinScale = 0.5;
  static const double _imageMaxScale = 5.0;
  double _imageScale = _imageMinScale;

  bool _imageConfirmed = false;
  bool _isUploadingFinal = false;

  bool get hasImage => _imageBytes != null;

  // url pubblico su supabase della PNG zoommata
  String _publicImageUrl = '';

  // key: area immagine zoomata
  final GlobalKey _imageBoundaryKey = GlobalKey();

  // key: intero honoo (testo + immagine) per export
  final GlobalKey _captureKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      _textCtrl.text = widget.initialText!;
    }

    _textCtrl.addListener(_emitChange);
    _textFocus.addListener(_handleFocusChange);
    _imageController.addListener(_handleImageTransform);

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
    final double raw = (sx > 0 && sy > 0)
        ? (sx + sy) / 2
        : (sx > 0 ? sx : (sy > 0 ? sy : _imageMinScale));
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

    _imageController.value = Matrix4.identity()
      ..translate(adjustedTx, adjustedTy)
      ..scale(clamped);

    setState(() => _imageScale = clamped);
  }

  void _nudgeImageScale(double delta) => _updateImageScale(_imageScale + delta);

  void _resetImageTransform() {
    _imageController.value = Matrix4.identity();
    setState(() => _imageScale = _imageMinScale);
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? selected =
          await picker.pickImage(source: ImageSource.gallery);
      if (selected == null) return;

      final Uint8List bytes = await selected.readAsBytes();

      _imageController.value = Matrix4.identity();

      setState(() {
        _imageBytes = bytes;

        // reset stato
        _publicImageUrl = '';
        _imageConfirmed = false;
        _isUploadingFinal = false;
        _confirmedPreviewBytes = null;
        _imageScale = _imageMinScale;
      });

      _emitChange();
    } catch (e) {
      if (!mounted) return;
      showHonooToast(context, message: 'Errore selezione immagine: $e');
    }
  }

  Future<Uint8List?> _captureZoomedImagePng() async {
    final boundary = _imageBoundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;

    try {
      final double pixelRatio = View.of(context).devicePixelRatio;
      final ui.Image img = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? bd = await img.toByteData(format: ui.ImageByteFormat.png);
      return bd?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Errore capture zoomed image: $e');
      return null;
    }
  }

  Future<void> _confirmImage() async {
    if (_imageConfirmed || !hasImage) return;

    final client = SupabaseProvider.client;
    final session = client.auth.currentSession;
    if (session == null) {
      if (!mounted) return;
      final bool? goLogin = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (_) => const HonooConfirmDialog(
          title: 'Devi accedere prima',
          message:
              'Per caricare un’immagine,\ndevi fare prima il login.\nVuoi andare alla pagina di login?',
          confirmLabel: 'Vai al login',
        ),
      );

      if (goLogin == true && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const EmailLoginPage(),
          ),
        );
      }
      return;
    }

    setState(() => _isUploadingFinal = true);

    // 1) cattura PNG zoommata (dalla preview)
    final Uint8List? png = await _captureZoomedImagePng();
    if (png == null || png.isEmpty) {
      if (!mounted) return;
      setState(() => _isUploadingFinal = false);
      showHonooToast(context,
          message: 'Impossibile confermare: PNG non generato.');
      return;
    }

    // 2) upload su supabase
    final String? publicUrl =
        await HonooImageUploader.uploadImageBytes(png, '.png');
    if (publicUrl == null || publicUrl.isEmpty) {
      if (!mounted) return;
      setState(() => _isUploadingFinal = false);
      showHonooToast(context, message: 'Upload immagine finale fallito.');
      return;
    }

    if (!mounted) return;
    setState(() {
      _publicImageUrl = publicUrl;
      _imageConfirmed = true;
      _isUploadingFinal = false;
      _confirmedPreviewBytes = png;
    });

    _emitChange();
  }

  Future<Uint8List?> _captureHonooAsPng() async {
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
      final Canvas canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, newWidth.toDouble(), newHeight.toDouble()),
      );

      canvas.drawRect(
        Rect.fromLTWH(0, 0, newWidth.toDouble(), newHeight.toDouble()),
        Paint()..color = HonooColor.background,
      );

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
      showHonooToast(context, message: 'Devi prima caricare un’immagine.');
      return;
    }

    final Uint8List? bytes = await _captureHonooAsPng();
    if (bytes == null || bytes.isEmpty) {
      if (!context.mounted) return;
      showHonooToast(context, message: 'Impossibile generare il file PNG.');
      return;
    }

    final saver = getDownloadSaver();

    final String fallbackName =
        'honoo_${DateTime.now().millisecondsSinceEpoch}';
    final String rawName = (fileName != null && fileName.trim().isNotEmpty)
        ? fileName.trim()
        : fallbackName;

    // ✅ NON uso saveBytes (così non tocchi download_saver.dart)
    await saver.save(
      [DownloadImage(filename: '$rawName.png', bytes: bytes)],
    );

    if (!context.mounted) return;
    showHonooToast(context, message: 'Download avviato.');
  }

  void resetContent() {
    setState(() {
      _textCtrl.clear();
      _imageBytes = null;

      _publicImageUrl = '';
      _imageController.value = Matrix4.identity();
      _imageScale = _imageMinScale;

      _imageConfirmed = false;
      _isUploadingFinal = false;

      _confirmedPreviewBytes = null;
    });

    _emitChange();
    widget.onFocusChanged?.call(false);
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
            (rawH - media.padding.vertical).clamp(0.0, double.infinity);

        if (availW <= 0 || availH <= 0) return const SizedBox.shrink();

        const double eps = 0.5;
        const double baselineTextHeight = HonooBuilder.baselineTextHeight;
        const double baselineTotalHeight = HonooBuilder.baselineTotalHeight;

        final double scaleW = availW / HonooBuilder.baselineImageSize;
        final double scaleH = (availH - eps) / baselineTotalHeight;
        final double scale =
            math.min(scaleW, scaleH).clamp(0.0, double.infinity);

        final double displayW = HonooBuilder.baselineImageSize * scale;
        final double displayH = baselineTotalHeight * scale;

        return Center(
          child: SizedBox(
            width: displayW,
            height: displayH,
            child: FittedBox(
              fit: BoxFit.contain,
              child: RepaintBoundary(
                key: _captureKey,
                child: SizedBox(
                  width: HonooBuilder.baselineImageSize,
                  height: baselineTotalHeight,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ===== TEXT AREA =====
                      SizedBox(
                        height: baselineTextHeight,
                        width: HonooBuilder.baselineImageSize,
                        child: _buildTextArea(HonooBuilder.baselineImageSize),
                      ),

                      const SizedBox(height: HonooBuilder.baselineGap),

                      // ===== IMAGE AREA =====
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Container(
                          width: HonooBuilder.baselineImageSize,
                          height: HonooBuilder.baselineImageSize,
                          color: Colors.white, // cornice neutra come “foglio”
                          child: _buildImageArea(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextArea(double imageSize) {
    return Container(
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

          return Stack(
            children: [
              Positioned.fill(
                child: WidthLimitedMultilineField(
                  controller: _textCtrl,
                  focusNode: _textFocus,
                  style: textStyle,
                  maxLines: 5,
                  maxCharsPerLine: 32,
                  horizontalPadding: const EdgeInsets.symmetric(horizontal: 22),
                  decoration: InputDecoration(
                    hintText: 'Scrivi qui il tuo testo',
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
                ),
              ),
              if (widget.onDownloadTap != null && widget.showDownloadButton)
                Positioned(
                  top: 8,
                  right: 8,
                  child: TextBoxDownloadButton(
                    onPressed: widget.onDownloadTap!,
                    tooltip: 'download',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildImageArea() {
    return GestureDetector(
      onTap: _imageConfirmed ? null : _pickImage,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Container(
          color: HonooColor.tertiary,
          child: _imageBytes == null
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
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    // ✅ se confermata: mostra la PNG zoommata catturata
                    if (_imageConfirmed && _confirmedPreviewBytes != null)
                      Image.memory(
                        _confirmedPreviewBytes!,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                      )
                    else
                      // ✅ PREVIEW (NO doppio zoom):
                      //    - niente FittedBox
                      //    - l’unico “fit” è sull’Image
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
                            child: SizedBox.expand(
                              child: Image(
                                image: MemoryImage(_imageBytes!),
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Overlay controlli finché non confermi
                    if (!_imageConfirmed) ...[
                      CambiaSfondoOverlay(
                        onTapChange: _pickImage,
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
                        child: _isUploadingFinal
                            ? const SizedBox(
                                width: 44,
                                height: 44,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              )
                            : IconButton(
                                iconSize: 44,
                                onPressed: _confirmImage,
                                tooltip: 'Conferma immagine',
                                icon: SvgPicture.asset(
                                  'assets/icons/ok.svg',
                                  width: 44,
                                  height: 44,
                                ),
                              ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
