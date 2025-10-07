// lib/UI/HinooBuilder/hinoobuilder.dart
// ============================================================================
// HinooBuilder – due pulsanti bianchi in ROW sopra il canvas,
// Canvas 9:16 in Card (r=5), anteprime SOTTO al canvas.
// Nessun overlay sopra il canvas o le anteprime.
// ============================================================================

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'HinooBuilder/overlays/cambiaSfondo.dart';
import 'HinooBuilder/overlays/coloreTesto.dart';
import 'HinooBuilder/overlays/scriviHinoo.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:honoo/Services/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Services/HinooStorageUploader.dart';
import 'package:honoo/Widgets/WhiteIconButton.dart';
import 'package:honoo/Widgets/honoo_dialogs.dart';
import 'package:honoo/UI/HinooBuilder/thumbnails/HinooThumbnails.dart';
import 'package:honoo/UI/HinooBuilder/dialogs/AnteprimaPNG.dart';
import 'package:honoo/UI/HinooBuilder/dialogs/DownloadHinooDialog.dart';
import 'package:honoo/UI/HinooBuilder/services/download_saver.dart';
import 'package:honoo/UI/HinooBuilder/dialogs/NameHinooDialog.dart';

// Import coerenti con la struttura HinooBuilder

// Wizard step (solo uno alla volta)
enum _WizardStep { changeBg, pickColor, writeText }


// ============================================================================
// Widget pubblico (callback opzionali)
// ============================================================================
class HinooBuilder extends StatefulWidget {
  const HinooBuilder({
    super.key,
    this.onHinooChanged,   // notifica il draft quando cambia qualcosa
    this.onPngExported,    // PNG generato (anteprima)
    this.embedThumbnails = true, // se false, mostra solo il canvas 9:16
  });

  final ValueChanged<dynamic>? onHinooChanged;
  final ValueChanged<Uint8List>? onPngExported;
  final bool embedThumbnails;

  @override
  State<HinooBuilder> createState() => _HinooBuilderState();
}

// ============================================================================
// Stato/Orchestrazione
// ============================================================================
class _HinooBuilderState extends State<HinooBuilder> {
  // Core
  final GlobalKey _captureKey = GlobalKey(); // SOLO il canvas è sotto questa key
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocus = FocusNode();

  // Modello semplificato (sostituisci "dynamic" con il tuo tipo Slide/Page)
  final List<dynamic> _pages = <dynamic>[];
  int _current = 0;

  // Trasformazioni testo sul canvas
  double _canvasHeight = 0;

  // Stato UI
  ImageProvider? _localBgPreview; // preview locale dello sfondo
  String? _bgPublicUrl;           // URL pubblico su storage
  Color _txtColor = Colors.white;
  _WizardStep _step = _WizardStep.changeBg;
  bool _bgChosen = false; // abilita bottone OK per procedere
  static const double _bgMinScale = 1.0;
  static const double _bgMaxScale = 5.0;
  final TransformationController _bgController = TransformationController();
  Matrix4? _bgLockedMatrix;
  double _bgScale = _bgMinScale;

  // Export/anteprima
  Uint8List? _lastPreviewBytes;
  String? _exportFilenameHint;
  String? _lastFileBaseName;

  // ========================================================================
  // Lifecycle
  // ========================================================================
  @override
  void initState() {
    super.initState();
    if (_pages.isEmpty) {
      _pages.add(_createEmptySlide());
    }
    _textController.addListener(() => _onCanvasTextChanged(_textController.text));
    _bgController.addListener(_handleBgTransform);
    _bgScale = _extractScaleFromMatrix(_bgController.value);
  }

  @override
  void dispose() {
    _textController.removeListener((){}); // safety no-op
    _textController.dispose();
    _textFocus.dispose();
    _bgController.removeListener(_handleBgTransform);
    _bgController.dispose();
    super.dispose();
  }

  void _handleBgTransform() {
    final double newScale = _extractScaleFromMatrix(_bgController.value);
    if ((newScale - _bgScale).abs() > 0.005) {
      setState(() => _bgScale = newScale);
    }
  }

  double _extractScaleFromMatrix(Matrix4 matrix) {
    final Float64List values = matrix.storage;
    final double sx = values[0].abs();
    final double sy = values[5].abs();
    double raw;
    if (sx > 0 && sy > 0) {
      raw = (sx + sy) / 2;
    } else if (sx > 0) {
      raw = sx;
    } else if (sy > 0) {
      raw = sy;
    } else {
      raw = _bgMinScale;
    }
    return raw.clamp(_bgMinScale, _bgMaxScale).toDouble();
  }

  void _updateBgScale(double scale) {
    final double clamped = scale.clamp(_bgMinScale, _bgMaxScale).toDouble();
    final Matrix4 current = _bgController.value.clone();
    final Float64List values = current.storage;
    final double currentScale = _extractScaleFromMatrix(current);
    final double safeScale = currentScale <= 0 ? _bgMinScale : currentScale;
    final double tx = values[12];
    final double ty = values[13];
    final double adjustedTx = tx * (safeScale / clamped);
    final double adjustedTy = ty * (safeScale / clamped);
    final Matrix4 updated = Matrix4.identity()
      ..translate(adjustedTx, adjustedTy)
      ..scale(clamped);
    _bgController.value = updated;
  }

  void _nudgeBgScale(double delta) {
    _updateBgScale(_bgScale + delta);
  }

  void _resetBgTransform() {
    _bgController.value = Matrix4.identity();
    setState(() {
      _bgScale = _bgMinScale;
      _bgLockedMatrix = null;
    });
  }

  void _applySlideState(dynamic slide) {
    final String text = _extractTextFromSlide(slide);
    if (_textController.text != text) {
      _textController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }

    final Color? textColor = _extractTextColorFromSlide(slide);
    if (textColor != null) {
      _txtColor = textColor;
    }

    final String? bgUrl = _extractBgUrlFromSlide(slide);
    _bgPublicUrl = (bgUrl != null && bgUrl.isNotEmpty) ? bgUrl : null;

    final Matrix4? transform = _extractBgTransformFromSlide(slide);
    if (transform != null) {
      _bgLockedMatrix = transform.clone();
      _bgController.value = transform.clone();
    } else if (_bgLockedMatrix != null) {
      _bgLockedMatrix = null;
      _bgController.value = Matrix4.identity();
    }

    _bgScale = _extractScaleFromMatrix(_bgController.value);
    _bgChosen = _localBgPreview != null || (_bgPublicUrl != null && _bgPublicUrl!.isNotEmpty);
  }

  void _resetToBlankState() {
    _textController.clear();
    _txtColor = Colors.white;
    _localBgPreview = null;
    _bgPublicUrl = null;
    _bgLockedMatrix = null;
    _bgController.value = Matrix4.identity();
    _bgScale = _bgMinScale;
    _bgChosen = false;
    _step = _WizardStep.changeBg;
  }

  Future<void> _openDownloadDialog() async {
    if (!mounted || _pages.isEmpty) return;
    final DownloadChoice? choice = await showDialog<DownloadChoice>(
      context: context,
      barrierDismissible: true,
      builder: (_) => DownloadHinooDialog(pageCount: _pages.length),
    );
    if (choice == null) return;
    final String? chosenName = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => NameHinooDialog(initialValue: _lastFileBaseName),
    );
    final String? trimmed = chosenName?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return;
    }
    _lastFileBaseName = trimmed;
    await _downloadHinoo(
      allPages: choice == DownloadChoice.allPages,
      baseName: trimmed,
    );
  }

  Future<void> _downloadHinoo({
    required bool allPages,
    String? baseName,
  }) async {
    if (!mounted) return;
    bool progressVisible = false;
    if (mounted) {
      progressVisible = true;
      // ignore: unawaited_futures
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const DownloadProgressDialog(),
      ).whenComplete(() => progressVisible = false);
    }

    final List<int> indices = allPages
        ? List<int>.generate(_pages.length, (int i) => i)
        : <int>[_current];
    final int previousIndex = _current;
    bool indexChanged = false;
    final List<DownloadImage> images = <DownloadImage>[];
    final DownloadSaver saver = getDownloadSaver();
    final String fileBaseName = _prepareFileBaseName(baseName);

    try {
      for (int pos = 0; pos < indices.length; pos++) {
        final int pageIndex = indices[pos];
        final bool switched = _current != pageIndex;
        _goTo(pageIndex);
        if (switched) indexChanged = true;
        await _waitForNextFrame();

        final Uint8List? bytes = await _captureCurrentCanvasBytes();
        if (bytes != null) {
          final String filename = _resolveFileName(
            baseName: fileBaseName,
            isMulti: indices.length > 1,
            pageNumber: pageIndex + 1,
          );
          images.add(DownloadImage(filename: filename, bytes: bytes));
        }
      }

      if (images.isEmpty) {
        throw Exception('Impossibile generare le immagini.');
      }

      final String message = await saver.save(
        images,
        message: 'Hinoo creati con Honoo',
      );
      if (!mounted) return;
      showHonooToast(
        context,
        message: message,
      );
    } catch (e) {
      if (mounted) {
        showHonooToast(
          context,
          message: 'Errore download: $e',
        );
      }
    } finally {
      if (indexChanged && mounted && _current != previousIndex) {
        _goTo(previousIndex);
        await _waitForNextFrame();
      }
      if (progressVisible && mounted) {
        final navigator = Navigator.of(context, rootNavigator: true);
        if (navigator.canPop()) {
          navigator.pop();
          progressVisible = false;
        }
      }
    }
  }

  Future<Uint8List?> _captureCurrentCanvasBytes({double pixelRatio = 3.0}) async {
    try {
      final RenderRepaintBoundary? boundary =
          _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('capture canvas error: $e');
      return null;
    }
  }

  Future<void> _waitForNextFrame() async {
    await Future<void>.delayed(Duration.zero);
    await WidgetsBinding.instance.endOfFrame;
  }

  Color? _extractTextColorFromSlide(dynamic slide) {
    if (slide is Map && slide['textColor'] is int) {
      return Color(slide['textColor'] as int);
    }
    return null;
  }

  String? _extractBgUrlFromSlide(dynamic slide) {
    if (slide is Map && slide['bgUrl'] is String) {
      final String value = slide['bgUrl'] as String;
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  Matrix4? _extractBgTransformFromSlide(dynamic slide) {
    if (slide is Map) {
      final dynamic raw = slide['bgTransform'];
      if (raw is List && raw.length == 16) {
        final List<double> values = raw.map((dynamic e) => (e as num).toDouble()).toList();
        return Matrix4.fromList(values);
      }
    }
    return null;
  }

  // ========================================================================
  // Helpers / API pubbliche
  // ========================================================================
  void goToPublic(int index) => _goTo(index); // vai alla pagina i
  void addPagePublic() => _addPage(); // aggiungi pagina
  void reorderPagesPublic(int oldIndex, int newIndex) =>
      _onReorder(oldIndex, newIndex);

  void deleteCurrentPagePublic() => _deleteCurrentPage(); // già usata
  Future<void> openPreviewDialogPublic() => _openPreviewDialog();
  Future<void> openDownloadDialogPublic() => _openDownloadDialog();
  Future<void> downloadAllPagesPublic({String? baseName}) =>
      _downloadHinoo(allPages: true, baseName: baseName);

  String _prepareFileBaseName(String? raw) {
    const String fallback = 'hinoo';
    final String? source = raw ?? _lastFileBaseName;
    if (source == null) return fallback;
    String base = source.trim();
    if (base.isEmpty) return fallback;
    base = base.replaceAll(RegExp(r'\s+'), '_');
    base = base.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
    if (base.isEmpty) return fallback;
    return base;
  }

  String _resolveFileName({
    required String baseName,
    required bool isMulti,
    required int pageNumber,
  }) {
    if (!isMulti) {
      return '$baseName.png';
    }
    final String suffix = pageNumber.toString().padLeft(2, '0');
    return '${baseName}_$suffix.png';
  }

  dynamic exportDraft() {
    return {
      'pages': _pages,                // sostituisci col tuo tipo slide/pagina
      'currentIndex': _current,
      'text': _textController.text,
      'textLength': _textController.text.trim().length,
      'textColor': _txtColor.value,
      'hasBg': _localBgPreview != null || _bgPublicUrl != null,
      'bgUrl': _bgPublicUrl,
      'bgTransform': _bgLockedMatrix?.storage.toList(),
      'canvasHeight': _canvasHeight,
      'step': _step.name,
      // preview immediata per thumbnails quando non c'è ancora un URL pubblico
      'bgPreviewBytes': _localBgPreview is MemoryImage
          ? (_localBgPreview as MemoryImage).bytes
          : null,
    };
  }

  void _notifyChanged() {
    final cb = widget.onHinooChanged;
    if (cb != null) cb(exportDraft());
  }

  // ========================================================================
  // Build — ROW pulsanti sopra, canvas 9:16 al centro, anteprime sotto
  // ========================================================================
  @override
  Widget build(BuildContext context) {
    // Quando embedThumbnails=false, il parent gestisce layout e 9:16.
    if (!widget.embedThumbnails) {
      const BorderRadius canvasRadius = BorderRadius.all(Radius.circular(5));
      return Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.black,
        shape: const RoundedRectangleBorder(borderRadius: canvasRadius),
        clipBehavior: Clip.antiAlias,
        child: _buildCanvas(context),
      );
    }

    return LayoutBuilder(
      builder: (context, box) {
        // Box 9:16 responsivo
        const double ar = 9 / 16;
        final double maxW = box.maxWidth;
        final double maxH = box.maxHeight;

        double targetW = maxW;
        double targetH = targetW / ar;          // h = w * 16/9
        if (targetH > maxH) {
          targetH = maxH;
          targetW = targetH * ar;               // w = h * 9/16
        }
        _canvasHeight = targetH;

        const double outerGap = 8;              // padding laterale
        const double thumbsH = 180;             // altezza thumbnails
        const BorderRadius canvasRadius = BorderRadius.all(Radius.circular(5));

        return Column(
          children: [
            // ===== Editor: pulsanti SOPRA + canvas 9:16 CENTRATO =====
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: outerGap),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- ROW di pulsanti bianchi, centrati, sopra il canvas ---
                      SizedBox(
                        width: targetW,
                        height: 44,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            WhiteIconButton(
                              tooltip: 'Scarica immagini',
                              icon: Icons.download_outlined,
                              onPressed: () => _openDownloadDialog(),
                            ),
                            const SizedBox(width: 12),
                            WhiteIconButton(
                              tooltip: 'Elimina pagina',
                              icon: Icons.delete_outline,
                              onPressed: _deleteCurrentPage,
                            ),
                          ],
                        ),
                      ),
                      // --- CANVAS 9:16 (Card con r=5, clip attiva) ---
                      SizedBox(
                        width: targetW,
                        height: targetH,
                        child: Card(
                          elevation: 0,
                          margin: EdgeInsets.zero,
                          color: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: canvasRadius),
                          clipBehavior: Clip.antiAlias,
                          child: _buildCanvas(context), // <-- RepaintBoundary è qui dentro
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ===== Barra miniature SOTTO al canvas =====
            SizedBox(
              height: thumbsH,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: outerGap, vertical: 8),
                child: AnteprimaHinoo(
                  pages: _pages,
                  currentIndex: _current,
                  onTapThumb: _goTo,
                  onAddPage: _addPage,
                  onReorder: _onReorder,
                  canvasHeight: targetH,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ========================================================================
  // Canvas (SOLO contenuto esportabile) — dentro la Card
  // ========================================================================
  Widget _buildCanvas(BuildContext context) {
    return RepaintBoundary(
      key: _captureKey,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Sfondo: usa sempre un unico percorso (asset di default oppure preview selezionata)
          Builder(
            builder: (_) {
              final ImageProvider provider = _localBgPreview ?? const AssetImage('assets/images/hinoo_default_1080x1920.png');
              final Widget fitted = FittedBox(
                fit: BoxFit.cover,
                child: Image(image: provider),
              );
              final bool interactive = (_step == _WizardStep.changeBg && _bgChosen && _localBgPreview != null);
              if (!interactive && _bgLockedMatrix != null) {
                _bgController.value = _bgLockedMatrix!.clone();
              }
              return ClipRect(
                child: InteractiveViewer(
                  transformationController: _bgController,
                  panEnabled: interactive,
                  scaleEnabled: interactive,
                  minScale: _bgMinScale,
                  maxScale: _bgMaxScale,
                  boundaryMargin: const EdgeInsets.all(200),
                  child: fitted,
                ),
              );
            },
          ),

          // Overlays sequenziali: uno solo alla volta
          if (_step == _WizardStep.changeBg)
            ...[
              CambiaSfondoOverlay(
                onTapChange: _pickAndUploadBackground,
                showControls: _bgChosen && _localBgPreview != null,
                currentScale: _bgScale,
                minScale: _bgMinScale,
                maxScale: _bgMaxScale,
                onScaleChanged: _bgChosen ? _updateBgScale : null,
                onZoomIn: _bgChosen && _bgScale < _bgMaxScale ? () => _nudgeBgScale(0.1) : null,
                onZoomOut: _bgChosen && _bgScale > _bgMinScale ? () => _nudgeBgScale(-0.1) : null,
                onResetTransform: _bgChosen ? _resetBgTransform : null,
              ),
              if (_bgChosen)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: IconButton(
                    iconSize: 44,
                    onPressed: _confirmBgAndLock,
                    icon: SvgPicture.asset('assets/icons/ok.svg', width: 44, height: 44),
                    tooltip: 'Conferma sfondo',
                  ),
                ),
            ]
          else if (_step == _WizardStep.pickColor)
            ColoreTestoOverlay(
              onPick: (c) {
                setState(() {
          _txtColor = c;
          // Propaga il colore su TUTTE le pagine per anteprime fedeli
          for (var i = 0; i < _pages.length; i++) {
            _pages[i] = _copySlideWithTextColor(_pages[i], _txtColor.value);
          }
          _step = _WizardStep.writeText;
        });
        FocusScope.of(context).requestFocus(_textFocus);
        _notifyChanged();
      },
            )
          else if (_step == _WizardStep.writeText)
            ScriviHinooOverlay(
              controller: _textController,
              focusNode: _textFocus,
              textColor: _txtColor,
            ),
        ],
      ),
    );
  }

  // ========================================================================
  // Gestione testo/pagine/riordino
  // ========================================================================
  void _onCanvasTextChanged(String v) {
    final s = _pages[_current];
    final updated = _copySlideWithText(s, v);
    setState(() => _pages[_current] = updated);
    _scheduleAutosave();
    _notifyChanged();
  }

  void _goTo(int index) {
    if (index < 0 || index >= _pages.length) return;
    setState(() {
      _current = index;
      _applySlideState(_pages[_current]);
    });
  }

  void _addPage() {
    setState(() {
      _pages.add(_createEmptySlide());
      _current = _pages.length - 1;
      _textController.clear();
      // mantieni anteprima sfondo globale
    });
    _scheduleAutosave();
    _notifyChanged();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _pages.removeAt(oldIndex);
      _pages.insert(newIndex, item);
      if (_current == oldIndex) {
        _current = newIndex;
      } else if (oldIndex < _current && newIndex >= _current) {
        _current -= 1;
      } else if (oldIndex > _current && newIndex <= _current) {
        _current += 1;
      }
    });
    _scheduleAutosave();
    _notifyChanged();
  }

  // Elimina pagina corrente (con conferma)
  Future<void> _deleteCurrentPage() async {
    if (_pages.isEmpty) return;

    final bool? ok = await showHonooDeleteDialog(
      context,
      target: HonooDeletionTarget.page,
    );

    if (ok != true) return;

    final int removedIndex = _current;

    setState(() {
      if (_pages.length > 1) {
        _pages.removeAt(removedIndex);
        final int newIndex = removedIndex > 0 ? removedIndex - 1 : 0;
        _current = newIndex.clamp(0, _pages.length - 1);
        _applySlideState(_pages[_current]);
      } else {
        _resetToBlankState();
        _pages[0] = _createEmptySlide();
        _current = 0;
      }
    });

    _scheduleAutosave();
    _notifyChanged();
  }

  // ========================================================================
  // Export PNG + Dialog
  // ========================================================================
  Future<void> _openPreviewDialog() async {
    await _renderCanvasAsPng();
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AnteprimaPNG(
        previewBytes: _lastPreviewBytes,
        filenameHint: _exportFilenameHint,
        onSavePng: _exportCanvasPng,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  Future<void> _renderCanvasAsPng() async {
    final Uint8List? bytes = await _captureCurrentCanvasBytes();
    if (bytes == null) return;
    setState(() {
      _lastPreviewBytes = bytes;
      _exportFilenameHint = 'hinoo_${DateTime.now().millisecondsSinceEpoch}.png';
    });
    final ValueChanged<Uint8List>? cb = widget.onPngExported;
    if (cb != null) cb(bytes);
  }

  Future<void> _exportCanvasPng() async {
    // TODO: salva/condividi _lastPreviewBytes secondo piattaforma (web/mobile)
    debugPrint('Salvataggio PNG... bytes: ${_lastPreviewBytes?.length}');
    Navigator.of(context).maybePop();
  }

  // ========================================================================
  // Autosave/Notify – collega al tuo servizio
  // ========================================================================
  void _scheduleAutosave() {
    // debounce/save
  }

  void _confirmBgAndLock() {
    setState(() {
      _bgLockedMatrix = _bgController.value.clone();
      _bgScale = _extractScaleFromMatrix(_bgLockedMatrix!);
      // Propaga la trasformazione a tutte le pagine
      for (var i = 0; i < _pages.length; i++) {
        _pages[i] = _copySlideWithBgTransform(_pages[i], _bgLockedMatrix!);
      }
      _step = _WizardStep.pickColor;
    });
    _notifyChanged();
    _scheduleAutosave();
  }

  // ========================================================================
  // Cambio sfondo – picking + upload storage (come HonooBuilder, adattato 9:16)
  // ========================================================================
  Future<void> _pickAndUploadBackground() async {
    try {
      final picker = ImagePicker();
      final XFile? selected = await picker.pickImage(source: ImageSource.gallery);
      if (selected == null) return;

      // Preview locale immediata
      final Uint8List bytes = await selected.readAsBytes();
      setState(() {
        _localBgPreview = MemoryImage(bytes);
        _bgChosen = true; // abilita OK per procedere
        _bgLockedMatrix = null;
        _bgScale = _bgMinScale;
      });
      _bgController.value = Matrix4.identity();

      _persistBgUrl(bytes, selected.name);
      _notifyChanged();
    } catch (e) {
      debugPrint('Errore cambio sfondo: $e');
      if (mounted) {
        showHonooToast(
          context,
          message: 'Errore sfondo: $e',
        );
      }
    }
  }

  Future<void> _persistBgUrl(Uint8List bytes, String originalName) async {
    try {
      final client = SupabaseProvider.client;
      final user = client.auth.currentUser;
      if (user == null) return; // opzionale: consenti preview locale senza upload

      final ext = _extensionFromName(originalName);
      final url = await HinooStorageUploader.uploadBackground(bytes: bytes, ext: ext, userId: user.id);
      setState(() {
        _bgPublicUrl = url;
      });

      // Propaga su tutte le pagine esistenti
      setState(() {
        for (var i = 0; i < _pages.length; i++) {
          _pages[i] = _copySlideWithBgUrl(_pages[i], url);
        }
      });
      _notifyChanged();
      _scheduleAutosave();
    } catch (e) {
      debugPrint('Upload sfondo fallito: $e');
    }
  }

  String _extensionFromName(String name) {
    final n = name.toLowerCase();
    final i = n.lastIndexOf('.');
    if (i < 0) return 'jpg';
    final e = n.substring(i + 1);
    if (e.length > 5) return 'jpg';
    return e;
  }

  // ========================================================================
  // Utility basiche per slide (se non hai un model)
  // ============================================================================
  dynamic _createEmptySlide() => {
        'text': '',
        'bgUrl': _bgPublicUrl,
        'textColor': _txtColor.value,
        if (_bgLockedMatrix != null) 'bgTransform': _bgLockedMatrix!.storage.toList(),
      };

  dynamic _copySlideWithText(dynamic slide, String text) {
    if (slide is Map) return {...slide, 'text': text};
    return slide;
  }

  dynamic _copySlideWithBgUrl(dynamic slide, String url) {
    if (slide is Map) return {...slide, 'bgUrl': url};
    return slide;
  }

  String _extractTextFromSlide(dynamic slide) {
    if (slide is Map && slide['text'] is String) return slide['text'] as String;
    return '';
  }

  dynamic _copySlideWithBgTransform(dynamic slide, Matrix4 m) {
    if (slide is Map) {
      return {
        ...slide,
        'bgTransform': m.storage.toList(),
      };
    }
    return slide;
  }

  dynamic _copySlideWithTextColor(dynamic slide, int colorValue) {
    if (slide is Map) return {...slide, 'textColor': colorValue};
    return slide;
  }

}
