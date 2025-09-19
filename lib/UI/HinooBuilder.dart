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
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Services/HinooStorageUploader.dart';
import 'package:honoo/Widgets/WhiteIconButton.dart';
import 'package:honoo/UI/HinooBuilder/thumbnails/HinooThumbnails.dart';
import 'package:honoo/UI/HinooBuilder/dialogs/AnteprimaPNG.dart';

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
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  double _canvasHeight = 0;

  // Stato UI
  ImageProvider? _localBgPreview; // preview locale dello sfondo
  String? _bgPublicUrl;           // URL pubblico su storage
  Color _txtColor = Colors.white;
  bool _showTextField = false;
  _WizardStep _step = _WizardStep.changeBg;
  bool _bgChosen = false; // abilita bottone OK per procedere
  final TransformationController _bgController = TransformationController();
  Matrix4? _bgLockedMatrix;

  // Export/anteprima
  Uint8List? _lastPreviewBytes;
  String? _exportFilenameHint;

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
  }

  @override
  void dispose() {
    _textController.removeListener((){}); // safety no-op
    _textController.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  // ========================================================================
  // Helpers / API pubbliche
  // ========================================================================
  void goToPublic(int index) => _goTo(index);            // vai alla pagina i
  void addPagePublic() => _addPage();                    // aggiungi pagina
  void reorderPagesPublic(int oldIndex, int newIndex) => _onReorder(oldIndex, newIndex);

  void deleteCurrentPagePublic() => _deleteCurrentPage(); // già usata
  Future<void> openPreviewDialogPublic() => _openPreviewDialog();

  dynamic exportDraft() {
    return {
      'pages': _pages,                // sostituisci col tuo tipo slide/pagina
      'currentIndex': _current,
      'text': _textController.text,
      'textColor': _txtColor.value,
      'hasBg': _localBgPreview != null || _bgPublicUrl != null,
      'bgUrl': _bgPublicUrl,
      'bgTransform': _bgLockedMatrix?.storage.toList(),
      'canvasHeight': _canvasHeight,
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
                              tooltip: 'Scarica immagine',
                              icon: Icons.download_outlined,
                              onPressed: _openPreviewDialog,
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
                  minScale: 1.0,
                  maxScale: 5.0,
                  boundaryMargin: const EdgeInsets.all(200),
                  child: fitted,
                ),
              );
            },
          ),

          // Overlays sequenziali: uno solo alla volta
          if (_step == _WizardStep.changeBg)
            ...[
              if (!_bgChosen)
                CambiaSfondoOverlay(onTapChange: _pickAndUploadBackground),
              if (_bgChosen)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: IconButton(
                    iconSize: 44,
                    onPressed: _confirmBgAndLock,
                    icon: SvgPicture.asset('assets/icons/ok.svg', width: 44, height: 44),
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
          _showTextField = false;
        });
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
    // TODO: aggiorna il tuo modello slide (qui esempio generico)
    final s = _pages[_current];
    final updated = _copySlideWithText(s, v);
    setState(() => _pages[_current] = updated);
    _scheduleAutosave();
    _notifyChanged();
  }

  void _goTo(int index) {
    if (index < 0 || index >= _pages.length) return;
    setState(() => _current = index);
  }

  void _addPage() {
    setState(() {
      _pages.add(_createEmptySlide());
      _current = _pages.length - 1;
      _textController.clear();
      _scale = 1.0;
      _offset = Offset.zero;
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

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminare questa pagina?'),
        content: const Text('L’operazione non è reversibile.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Elimina')),
        ],
      ),
    );

    if (ok != true) return;

    setState(() {
      if (_pages.length > 1) {
        _pages.removeAt(_current);
        if (_current >= _pages.length) _current = _pages.length - 1;

        // Reset base (adatta al tuo modello)
        _textController.text = _extractTextFromSlide(_pages[_current]);
        _txtColor = Colors.white;
        _scale = 1.0;
        _offset = Offset.zero;
        _localBgPreview = null;
      } else {
        // mantieni almeno una pagina vuota
        _pages[0] = _createEmptySlide();
        _current = 0;
        _textController.clear();
        _txtColor = Colors.white;
        _scale = 1.0;
        _offset = Offset.zero;
        _localBgPreview = null;
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
    try {
      final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List bytes = byteData!.buffer.asUint8List();
      setState(() {
        _lastPreviewBytes = bytes;
        _exportFilenameHint = 'hinoo_${DateTime.now().millisecondsSinceEpoch}.png';
      });
      final cb = widget.onPngExported;
      if (cb != null) cb(bytes);
    } catch (e) {
      debugPrint('render PNG error: $e');
    }
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
      });

      _persistBgUrl(bytes, selected.name);
      _notifyChanged();
    } catch (e) {
      debugPrint('Errore cambio sfondo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore sfondo: $e')),
        );
      }
    }
  }

  Future<void> _persistBgUrl(Uint8List bytes, String originalName) async {
    try {
      final client = Supabase.instance.client;
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

// ---------------------------------------------------------------------------
// Helper top-level: pulsante bianco rotondo (privato al file)
// ---------------------------------------------------------------------------
class _WhiteIconButton extends StatelessWidget {
  const _WhiteIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    super.key,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: Colors.black),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.all(8),
        shape: const CircleBorder(),
        elevation: 2,
      ),
    );
  }
}
// ^ Non più usato: il pulsante viene fornito da lib/Widgets/WhiteIconButton.dart
