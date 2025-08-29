// lib/UI/HinooBuilder.dart
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb; // ← per distinguere web
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:honoo/Utility/HonooColors.dart';
import 'package:honoo/Controller/HinooController.dart';
import 'package:honoo/Utility/image_normalizer.dart';

// Mantengo il tuo path (coerente col progetto che hai caricato)

// ⬇⬇ Import condizionale per il download su Web
import 'package:honoo/Utility/download_stub.dart'
    if (dart.library.html) 'package:honoo/Utility/download_web.dart' as webdl;

import '../Entities/Hinoo.dart';

typedef HinooChanged = void Function(HinooDraft draft);
typedef HinooPngExported = void Function(Uint8List pngBytes);

class HinooBuilder extends StatefulWidget {
  final HinooChanged? onHinooChanged;

  // ✅ Reply mode / inizializzazione
  final HinooType initialType;
  final String? initialReplyTo;
  final String? initialRecipientTag;

  // ✅ Autosave
  final bool autosaveEnabled;
  final Duration autosaveDebounce;

  // ✅ PNG export callback (opzionale)
  final HinooPngExported? onPngExported;

  const HinooBuilder({
    super.key,
    this.onHinooChanged,
    this.initialType = HinooType.personal,
    this.initialReplyTo,
    this.initialRecipientTag,
    this.autosaveEnabled = true,
    this.autosaveDebounce = const Duration(milliseconds: 1500),
    this.onPngExported,
  });

  @override
  State<HinooBuilder> createState() => HinooBuilderState();
}

class HinooBuilderState extends State<HinooBuilder> {
  static const int _maxPages = 9;

  final PageController _pageController = PageController();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _replyCtrl = TextEditingController();
  final TextEditingController _recipCtrl = TextEditingController();

  // Controller per storage + service
  final HinooController _controller = HinooController();

  // Stato multipagina
  List<HinooSlide> _pages = const [
    HinooSlide(
        backgroundImage: null,
        text: '',
        isTextWhite: true,
        bgScale: 1.0,
        bgOffsetX: 0.0,
        bgOffsetY: 0.0),
  ];
  int _current = 0;

  void _syncFromSlideTransform() {
    final s = _pages[_current];
    _scale = s.bgScale;
    _offset = Offset(s.bgOffsetX, s.bgOffsetY);
  }

  // Stato generale del draft
  late HinooType _type;
  String? _replyTo;
  String? _recipientTag;

  // Stato sfondo: interazione prima del lock
  bool _bgLocked = false;
  double _scale = 1.0;
  Offset _offset = Offset.zero;

  double _scaleStart = 1.0;
  Offset _offsetStart = Offset.zero;
  Offset _focalStart = Offset.zero;

  // ✅ Autosave
  Timer? _autosaveTimer;

  // ✅ stato caricamento bozza
  bool _loadingDraft = true;

  // ✅ Export PNG
  final GlobalKey _captureKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _replyTo = widget.initialReplyTo;
    _recipientTag = widget.initialRecipientTag;
    _replyCtrl.text = _replyTo ?? '';
    _recipCtrl.text = _recipientTag ?? '';
    _syncTextController();

    // 1) tenta restore bozza (🛠️ prima era fuori dalla classe: ora è qui)
    _restoreDraft();
  }

  Future<void> _restoreDraft() async {
    try {
      final draft = await _controller.getDraft();
      if (draft != null && mounted) {
        setState(() {
          _type = draft.type;
          _replyTo = draft.replyTo;
          _recipientTag = draft.recipientTag;
          _pages = draft.pages.isNotEmpty
              ? List<HinooSlide>.from(draft.pages)
              : const [
                  HinooSlide(backgroundImage: null, text: '', isTextWhite: true)
                ];
          _current = 0;
          // uniforma sfondo a quello della pagina 1
          _enforceGlobalBackgroundAfterRestore();
        });
        _syncTextController();
        _replyCtrl.text = _replyTo ?? '';
        _recipCtrl.text = _recipientTag ?? '';
        // non triggero autosave qui
      }
    } catch (_) {
      // ignora errori restore
    } finally {
      if (mounted) {
        setState(() => _loadingDraft = false);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _textController.dispose();
    _autosaveTimer?.cancel();
    _replyCtrl.dispose();
    _recipCtrl.dispose();
    super.dispose();
  }

  /// Draft attuale (inclusi type/reply)
  HinooDraft exportDraft() => HinooDraft(
        pages: List.unmodifiable(_pages),
        type: _type,
        replyTo: _replyTo,
        recipientTag: _recipientTag,
      );

  void _notify() {
    final d = exportDraft();
    widget.onHinooChanged?.call(d);
    _scheduleAutosave(d);
  }

  // ========= AUTOSAVE =========
  void _scheduleAutosave(HinooDraft draft) {
    if (!widget.autosaveEnabled) return;
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(widget.autosaveDebounce, () async {
      try {
        await _controller.saveDraft(draft);
        // (silenzioso) — se vuoi feedback, qui puoi mostrare uno snack leggero
      } catch (_) {
        // ignora errori autosave
      }
    });
  }

  // ========= BACKGROUND UPLOAD =========
  Future<void> _pickBackgroundAndUpload() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );
      if (file == null) return;

      final Uint8List raw = await file.readAsBytes();
      final String rawExt = _inferExt(file.name);

      final normalized = await normalizeBackgroundImage(
        raw,
        originalExt: rawExt,
        // volendo puoi passare maxUploadBytes/maxW/maxH diversi
      );

      final Uint8List bytes = normalized.bytes;
      final String ext = normalized.ext;

      final publicUrl =
          await _controller.uploadBackgroundBytes(bytes, ext: ext);

      final slide = _pages[_current].copyWith(
        backgroundImage: publicUrl,
        bgScale: 1.0,
        bgOffsetX: 0.0,
        bgOffsetY: 0.0,
      );

      setState(() {
        // forza che la modifica avvenga sulla pagina 1
        _pages[0] = (_current == 0
            ? slide
            : _pages[0].copyWith(
                backgroundImage: publicUrl,
                bgScale: 1.0,
                bgOffsetX: 0.0,
                bgOffsetY: 0.0,
              ));

        // propaga a tutte le altre
        _propagateBackgroundFromFirst();

        // stato runtime per preview corrente
        _bgLocked = false;
        _scale = 1.0;
        _offset = Offset.zero;
      });
      _notify();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload sfondo fallito: $e')),
      );
    }
  }

  String _inferExt(String filename) {
    final i = filename.lastIndexOf('.');
    if (i <= 0) return 'jpg';
    final raw = filename.substring(i + 1).toLowerCase();
    if (raw == 'jpeg') return 'jpg';
    const allowed = ['jpg', 'png', 'webp'];
    return allowed.contains(raw) ? raw : 'jpg';
  }

  // ========= EXPORT PNG =========
  Future<Uint8List?> exportCanvasPng({double pixelRatio = 3.0}) async {
    try {
      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  /// (mantengo il tuo metodo – ora non usato dalla toolbar ma disponibile)
  Future<void> _exportPngAndNotify() async {
    final png = await exportCanvasPng(pixelRatio: 3.0);
    if (png == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export PNG fallito.')),
      );
      return;
    }
    widget.onPngExported?.call(png);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PNG esportato.')),
    );
  }

  /// 👉 nuovo: apre anteprima con azioni (Salva su Storage / Download Web)
  Future<void> _openPngPreview() async {
    final png = await exportCanvasPng(pixelRatio: 3.0);
    if (png == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Export PNG fallito.')));
      return;
    }

    // Dialog anteprima
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => _PngPreviewDialog(
        pngBytes: png,
        onSaveToStorage: () async {
          try {
            final url = await _controller.uploadCanvasPng(png);
            if (!mounted) return;
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('PNG salvato: $url')));
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Errore salvataggio: $e')));
          }
        },
        onDownloadLocal: () async {
          if (kIsWeb) {
            webdl.downloadBytes(
              png,
              filename: 'hinoo-${DateTime.now().millisecondsSinceEpoch}.png',
              mimeType: 'image/png',
            );
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Download locale disponibile solo su Web.')),
            );
          }
        },
      ),
    );

    // callback opzionale esterna
    widget.onPngExported?.call(png);
  }

  // ========= EDITING =========
  void _toggleLock() {
    setState(() => _bgLocked = !_bgLocked);
  }

  void _toggleTextColor() {
    final slide = _pages[_current];
    setState(() =>
        _pages[_current] = slide.copyWith(isTextWhite: !slide.isTextWhite));
    _notify();
  }

  void _onTextChanged(String v) {
    final slide = _pages[_current];
    setState(() => _pages[_current] = slide.copyWith(text: v));
    _notify();
  }

  void _addPage() {
    if (_pages.length >= _maxPages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Puoi creare al massimo 9 schermate.')),
      );
      return;
    }
    setState(() {
      final first = _pages.first;
      _pages = List.of(_pages)
        ..add(
          HinooSlide(
            backgroundImage: first.backgroundImage,
            text: '',
            isTextWhite: true,
            bgScale: first.bgScale,
            bgOffsetX: first.bgOffsetX,
            bgOffsetY: first.bgOffsetY,
          ),
        );
    });
    _goTo(_pages.length - 1);
    _notify();
  }

  void _removePage() {
    if (_pages.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deve esserci almeno una schermata.')),
      );
      return;
    }
    // ✅ Consenti rimozione solo dell’ultima pagina
    if (_current != _pages.length - 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Puoi rimuovere solo l’ultima pagina.')),
      );
      return;
    }

    // ...il resto rimane uguale...
    setState(() {
      final newPages = List.of(_pages)..removeAt(_current);
      _pages = newPages;
      _current = math.max(0, _current - 1);
    });
    _pageController.jumpToPage(_current);
    _syncTextController();
    _notify();
  }

  void _goTo(int index) {
    _current = index.clamp(0, _pages.length - 1);
    _pageController.animateToPage(
      _current,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
    );
    _syncTextController();
  }

  void _next() => _goTo((_current + 1).clamp(0, _pages.length - 1));

  void _prev() => _goTo((_current - 1).clamp(0, _pages.length - 1));

  void _syncTextController() {
    _textController.text = _pages[_current].text;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: _textController.text.length),
    );
    _syncFromSlideTransform(); // ✅ aggiungi questa riga
  }

  void _onScaleStart(ScaleStartDetails d) {
    if (_bgLocked) return;
    // sfondo globale editabile SOLO nella pagina 1
    if (_current != 0) return;

    _scaleStart = _scale;
    _offsetStart = _offset;
    _focalStart = d.focalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    if (_bgLocked) return;
    if (_current != 0) return;

    // 1) scala ancorata al valore di start
    final newScale = (_scaleStart * d.scale).clamp(0.5, 5.0);

    // 2) mantieni “ancorato” il punto sotto il dito (focal point)
    //    calcolando la posizione locale del punto focale a inizio gesto
    final focalStartLocal = (_focalStart - _offsetStart) / _scaleStart;
    final newOffset = d.focalPoint - focalStartLocal * newScale;

    setState(() {
      _scale = newScale;
      _offset = newOffset;

      // aggiorna la pagina 1 (sfondo globale)
      _pages[0] = _pages[0].copyWith(
        bgScale: _scale,
        bgOffsetX: _offset.dx,
        bgOffsetY: _offset.dy,
      );

      // propaga a tutte le altre pagine
      _propagateBackgroundFromFirst();
    });

    _notify();
  }

  void _onScaleEnd(ScaleEndDetails d) {}

  void _propagateBackgroundFromFirst() {
    if (_pages.isEmpty) return;
    final first = _pages.first;
    for (int i = 1; i < _pages.length; i++) {
      _pages[i] = _pages[i].copyWith(
        backgroundImage: first.backgroundImage,
        bgScale: first.bgScale,
        bgOffsetX: first.bgOffsetX,
        bgOffsetY: first.bgOffsetY,
      );
    }
  }
  Widget _thumbnailsBar() {
    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _pages.length,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (context, i) {
          final s = _pages[i];
          final bool isCurrent = i == _current;
          return GestureDetector(
            onTap: () => _goTo(i),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCurrent ? HonooColor.secondary : Colors.black26,
                  width: isCurrent ? 2 : 1,
                ),
              ),
              child: SizedBox(
                height: 88,
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (s.backgroundImage != null && s.backgroundImage!.isNotEmpty)
                          Image.network(s.backgroundImage!, fit: BoxFit.cover)
                        else
                          const ColoredBox(color: Colors.black12),

                        // badge con numero pagina
                        Positioned(
                          right: 6,
                          bottom: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
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
      ),
    );
  }

  /// Se una bozza vecchia ha sfondi diversi, uniforma tutto alla 1ª.
  void _enforceGlobalBackgroundAfterRestore() {
    if (_pages.length <= 1) return;
    _propagateBackgroundFromFirst();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingDraft) {
      return const Center(child: CircularProgressIndicator());
    }

    final slide = _pages[_current];
    final txtColor = slide.isTextWhite ? Colors.white : Colors.black;

    return Column(
      children: [
        _Toolbar(
          current: _current + 1,
          total: _pages.length,
          onPrev: _prev,
          onNext: _next,
          onAdd: _addPage,
          onRemove: (_pages.length > 1 && _current == _pages.length - 1)
              ? _removePage
              : () {},
          replyController: _replyCtrl,
          // 👈 nuovo
          recipientController: _recipCtrl,
          type: _type,
          onTypeChanged: (t) {
            setState(() => _type = t);
            _notify();
          },
          // ✅ Reply mode inline (campi opzionali)
          replyTo: _replyTo,
          recipientTag: _recipientTag,
          onReplyChanged: (replyTo, recipient) {
            setState(() {
              _replyTo = replyTo?.trim().isEmpty == true ? null : replyTo;
              _recipientTag =
                  recipient?.trim().isEmpty == true ? null : recipient;
            });
            _notify();
          },
          // ✅ Ora apre l’anteprima con azioni
          onExportPng: _openPngPreview,
        ),

        const SizedBox(height: 8),

        // Editor verticale 16:9 (9/16) — avvolto in RepaintBoundary per export PNG
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: RepaintBoundary(
                key: _captureKey,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black26, width: 1),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (slide.backgroundImage != null &&
                          slide.backgroundImage!.isNotEmpty)
                        GestureDetector(
                          onScaleStart: _onScaleStart,
                          onScaleUpdate: _onScaleUpdate,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Transform.translate(
                              offset: _offset,
                              child: Transform.scale(
                                scale: _scale,
                                child: Image.network(
                                  slide.backgroundImage!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const ColoredBox(color: Colors.black12),
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        const ColoredBox(color: Colors.black12),

                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: IgnorePointer(
                            ignoring: true,
                            child: Text(
                              slide.text,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.libreFranklin(
                                color: txtColor,
                                fontSize: 22,
                                height: 1.25,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Pulsanti sfondo/lock
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: Row(
                          children: [
                            Tooltip(
                              message: _current == 0
                                  ? 'Scegli un’immagine di sfondo'
                                  : 'Modifica lo sfondo dalla pagina 1',
                              waitDuration: const Duration(milliseconds: 300),
                              child: ElevatedButton.icon(
                                onPressed: _current == 0 ? _pickBackgroundAndUpload : null,
                                icon: const Icon(Icons.image_outlined),
                                label: const Text('Sfondo'),
                              ),
                            ),

                            const SizedBox(width: 8),
                            Tooltip(
                              message: (_current == 0)
                                  ? (slide.backgroundImage == null || slide.backgroundImage!.isEmpty
                                  ? 'Carica uno sfondo per poterlo bloccare'
                                  : (_bgLocked ? 'Sblocca lo sfondo' : 'Blocca lo sfondo'))
                                  : 'Disponibile solo nella pagina 1',
                              waitDuration: const Duration(milliseconds: 300),
                              child: OutlinedButton.icon(
                                onPressed: (_current == 0 && slide.backgroundImage != null && slide.backgroundImage!.isNotEmpty)
                                    ? _toggleLock
                                    : null,
                                icon: Icon(_bgLocked ? Icons.lock : Icons.lock_open),
                                label: Text(_bgLocked ? 'Bloccato' : 'Sblocca'),
                              ),
                            ),

                          ],
                        ),
                      ),

                      // Toggle colore testo
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: ElevatedButton.icon(
                          onPressed: _toggleTextColor,
                          icon: Icon(slide.isTextWhite
                              ? Icons.format_color_text
                              : Icons.format_color_fill),
                          label: Text(slide.isTextWhite
                              ? 'Testo bianco'
                              : 'Testo nero'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),
        _thumbnailsBar(),

        if (_current != 0) ...[
          const SizedBox(height: 6),
          Text(
            'Lo sfondo vale per tutte le pagine. Modificalo dalla pagina 1.',
            style:
                GoogleFonts.libreFranklin(fontSize: 12, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 12),

        // Input testo (centrato nel preview)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TextField(
            controller: _textController,
            onChanged: _onTextChanged,
            textAlign: TextAlign.center,
            maxLines: 3,
            inputFormatters: [LengthLimitingTextInputFormatter(300)],
            decoration: InputDecoration(
              hintText: 'Scrivi il testo dell’hinoo…',
              hintStyle: GoogleFonts.libreFranklin(
                  color: HonooColor.onBackground.withOpacity(0.5)),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

class _Toolbar extends StatelessWidget {
  final int current;
  final int total;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  final HinooType type;
  final ValueChanged<HinooType> onTypeChanged;
  final TextEditingController replyController;
  final TextEditingController recipientController;

  // ✅ Reply UI (semplice, opzionale)
  final String? replyTo;
  final String? recipientTag;
  final void Function(String? replyTo, String? recipientTag) onReplyChanged;

  // ✅ Export PNG
  final VoidCallback onExportPng;

  const _Toolbar({
    required this.current,
    required this.total,
    required this.onPrev,
    required this.onNext,
    required this.onAdd,
    required this.onRemove,
    required this.type,
    required this.onTypeChanged,
    required this.replyTo,
    required this.recipientTag,
    required this.onReplyChanged,
    required this.onExportPng,
    required this.replyController,
    required this.recipientController,
  });



  @override
  Widget build(BuildContext context) {
    // colori coerenti con Honoo
    Color chipColor(HinooType t) {
      switch (t) {
        case HinooType.moon:
          return HonooColor.tertiary; // come HonooType.moon
        case HinooType.answer:
          return HonooColor.secondary; // come HonooType.answer
        case HinooType.personal:
        default:
          return HonooColor.background; // come HonooType.personal
      }
    }

    return Row(
      children: [
        const SizedBox(width: 4),
        IconButton(
            onPressed: current > 1 ? onPrev : null,
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Precedente'),
        Text('$current / $total',
            style: GoogleFonts.libreFranklin(
                fontSize: 16, fontWeight: FontWeight.w600)),
        IconButton(
            onPressed: current < total ? onNext : null,
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'Successiva'),
        const Spacer(),

        // Selettore TYPE con colori come Honoo
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ChoiceChip(
              selected: type == HinooType.personal,
              label: const Text('Personal'),
              selectedColor: chipColor(HinooType.personal),
              onSelected: (_) => onTypeChanged(HinooType.personal),
            ),
            ChoiceChip(
              selected: type == HinooType.moon,
              label: const Text('Moon'),
              selectedColor: chipColor(HinooType.moon),
              onSelected: (_) => onTypeChanged(HinooType.moon),
            ),
            ChoiceChip(
              selected: type == HinooType.answer,
              label: const Text('Answer'),
              selectedColor: chipColor(HinooType.answer),
              onSelected: (_) => onTypeChanged(HinooType.answer),
            ),

            // Reply fields (mostrali solo in Answer)
            if (type == HinooType.answer)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 160,
                    child: TextField(
                      controller: replyController, // ✅
                      decoration: const InputDecoration(
                        isDense: true,
                        labelText: 'Reply to (id)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => onReplyChanged(
                          replyController.text, recipientController.text),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 140,
                    child: TextField(
                      controller: recipientController, // ✅
                      decoration: const InputDecoration(
                        isDense: true,
                        labelText: 'Recipient tag',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => onReplyChanged(
                          replyController.text, recipientController.text),
                    ),
                  ),
                ],
              ),
          ],
        ),

        const SizedBox(width: 12),

        // Export PNG → ora apre la preview
        OutlinedButton.icon(
          onPressed: onExportPng,
          icon: const Icon(Icons.image),
          label: const Text('Export PNG'),
        ),

        const SizedBox(width: 12),
        OutlinedButton.icon(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Rimuovi')),
        const SizedBox(width: 8),
        ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Aggiungi')),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ====== Dialog di anteprima PNG 9:16 ======
class _PngPreviewDialog extends StatelessWidget {
  final Uint8List pngBytes;
  final Future<void> Function() onSaveToStorage;
  final Future<void> Function() onDownloadLocal;

  const _PngPreviewDialog({
    required this.pngBytes,
    required this.onSaveToStorage,
    required this.onDownloadLocal,
  });



  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Anteprima 9:16',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 9 / 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(pngBytes, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Chiudi'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDownloadLocal,
                      icon: const Icon(Icons.download),
                      label: const Text('Download'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onSaveToStorage,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Salva'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
