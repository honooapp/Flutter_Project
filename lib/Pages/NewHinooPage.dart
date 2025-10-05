// lib/Pages/NewHinooPage.dart
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:honoo/Utility/HonooColors.dart';
import 'package:honoo/Utility/Utility.dart';
import 'package:honoo/Widgets/LunaFissa.dart';
import 'package:honoo/Widgets/honoo_dialogs.dart';

import 'package:honoo/Controller/HinooController.dart';

import '../UI/HinooBuilder.dart';
import '../Widgets/WhiteIconButton.dart';
// IMPORT del tuo widget thumbnails esterno
import 'package:honoo/UI/HinooBuilder/thumbnails/HinooThumbnails.dart';

import 'ChestPage.dart';
import 'EmailLoginPage.dart';
import '../Entities/Hinoo.dart';

class NewHinooPage extends StatefulWidget {
  const NewHinooPage({super.key});

  @override
  State<NewHinooPage> createState() => _NewHinooPageState();
}

class _NewHinooPageState extends State<NewHinooPage> {
  // Chiave per interrogare/controllare il builder
  final GlobalKey _builderKey = GlobalKey();

  final _controller = HinooController();
  bool _savedToChest = false;

  // Stato locale per collegare AnteprimaHinoo
  List<dynamic> _pages = const [];
  int _currentIndex = 0;
  String? _globalBgUrl;
  List<dynamic>? _globalBgTransform;
  Uint8List? _globalBgPreviewBytes;
  double _lastCanvasHeight = 0;
  String _builderStep = 'changeBg';
  int _currentTextLength = 0;

  bool get _isWriteStep => _builderStep == 'writeText';
  bool get _hasMinTextForDownload => _currentTextLength >= 1;

  // Costanti layout
  static const double _titleH = 52; // riga titolo
  static const double _controlsH = 44; // riga bottoni bianchi visibili
  static const double _thumbsH = 140;
  static const double _footerH = 100.0; // riserva spazio per la navbar

  @override
  void initState() {
    super.initState();
    // Dopo il primo frame, prova a leggere il draft dal builder per popolare thumbnails
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dyn = _builderKey.currentState as dynamic;
      final draft = dyn?.exportDraft?.call();
      if (!mounted) return;
      setState(() => _applyDraftToLocalState(draft));
    });
  }

  // Callback dal builder: ogni modifica torna allo stato "OK" + sync thumbnails
  void _onHinooChanged(dynamic draft) {
    setState(() {
      if (_savedToChest) _savedToChest = false;
      _applyDraftToLocalState(draft);
    });
  }

  void _applyDraftToLocalState(dynamic draft) {
    if (draft is! Map) return;

    final dynamic p = draft['pages'];
    if (p is List) _pages = p;

    final dynamic idx = draft['currentIndex'];
    if (idx is int) {
      final int max = _pages.isEmpty ? 0 : _pages.length - 1;
      _currentIndex = idx.clamp(0, max);
    } else if (_currentIndex >= _pages.length) {
      _currentIndex = _pages.isEmpty ? 0 : _pages.length - 1;
    }

    _globalBgUrl = draft['bgUrl'] as String?;
    final dynamic tr = draft['bgTransform'];
    _globalBgTransform = (tr is List) ? tr : null;
    final dynamic bytes = draft['bgPreviewBytes'];
    _globalBgPreviewBytes = (bytes is Uint8List) ? bytes : null;
    final dynamic ch = draft['canvasHeight'];
    if (ch is num) _lastCanvasHeight = ch.toDouble();

    final dynamic rawStep = draft['step'];
    if (rawStep is String && rawStep.isNotEmpty) {
      _builderStep = rawStep;
    }

    int detectedLength = 0;
    final dynamic rawLength = draft['textLength'];
    if (rawLength is int) {
      detectedLength = rawLength;
    } else {
      final dynamic rawText = draft['text'];
      if (rawText is String) detectedLength = rawText.trim().length;
    }
    _currentTextLength = detectedLength;
  }

  // PNG opzionale dal builder
  Future<void> _onPngExported(Uint8List bytes) async {
    if (!mounted) return;
    showHonooToast(
      context,
      message: 'PNG generato: pronto per salvare o condividere.',
    );
  }

  // Azioni footer
  Future<void> _submitHinoo() async {
    final dynamic rawDraft =
        (_builderKey.currentState as dynamic)?.exportDraft();
    final pages = (rawDraft is Map) ? (rawDraft['pages'] as List?) : null;
    if (rawDraft == null || pages == null || pages.isEmpty) {
      if (!mounted) return;
      showHonooToast(
        context,
        message: 'Crea almeno una schermata 9:16 con sfondo e testo.',
      );
      return;
    }

    // Converte il draft grezzo del builder nel modello HinooDraft (Entities/Hinoo.dart)
    final HinooDraft hinooDraft = _convertRawBuilderDraft(rawDraft);
    final validationErrors = _controller.validateDraft(hinooDraft);
    if (validationErrors.isNotEmpty) {
      if (!mounted) return;
      final errorText = 'Bozza non valida:\n- ${validationErrors.join('\n- ')}';
      showHonooToast(
        context,
        message: errorText,
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      // Porta in login passando la bozza da salvare dopo l'accesso
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EmailLoginPage(
            pendingHinooDraft: hinooDraft.toJson(),
          ),
        ),
      );
      return;
    }

    try {
      await _controller.saveToChest(hinooDraft);
      if (!mounted) return;
      setState(() => _savedToChest = true);
      showHonooToast(
        context,
        message: 'Hinoo salvato nello scrigno.',
      );
    } catch (e) {
      if (!mounted) return;
      showHonooToast(
        context,
        message: 'Errore: $e',
      );
    }
  }

  // Converte il draft prodotto da HinooBuilder (Map) nel tipo HinooDraft
  HinooDraft _convertRawBuilderDraft(Map raw) {
    final List<dynamic> rawPages = (raw['pages'] as List<dynamic>? ?? []);
    final List<HinooSlide> slides = [];
    for (final p in rawPages) {
      if (p is Map) {
        final bgUrl = p['bgUrl'] as String?;
        final txt = ((p['text'] as String?) ?? '').trim();
        final textColorVal = (p['textColor'] as int?) ?? 0xFFFFFFFF;
        final isTextWhite = textColorVal == const Color(0xFFFFFFFF).value;
        // Estrai scale e offset (se presenti) dalla matrice 4x4
        double scale = 1.0;
        double offX = 0.0;
        double offY = 0.0;
        List<double>? normalizedTransform;
        final tr = p['bgTransform'];
        if (tr is List && tr.length == 16) {
          final List<double> m = tr.map((e) => (e as num).toDouble()).toList();
          scale = m[0];
          offX = m[12];
          offY = m[13];

          const double designHeight = 1920;
          const double designWidth = 1080;
          final double canvasH =
              _lastCanvasHeight > 0 ? _lastCanvasHeight : designHeight;
          final double canvasW = canvasH * (9 / 16);
          final double factorX = canvasW != 0 ? designWidth / canvasW : 1.0;
          final double factorY = canvasH != 0 ? designHeight / canvasH : 1.0;

          normalizedTransform = List<double>.from(m);
          normalizedTransform[12] = m[12] * factorX;
          normalizedTransform[13] = m[13] * factorY;

          offX = normalizedTransform[12];
          offY = normalizedTransform[13];
        }
        slides.add(HinooSlide(
          backgroundImage: bgUrl,
          text: txt,
          isTextWhite: isTextWhite,
          bgScale: scale,
          bgOffsetX: offX,
          bgOffsetY: offY,
          bgTransform: normalizedTransform,
        ));
      }
    }
    return HinooDraft(
      pages: slides,
      type: HinooType.personal,
      baseCanvasHeight: _lastCanvasHeight > 0 ? _lastCanvasHeight : null,
    );
  }

  Future<void> _submitToMoon() async {
    final dynamic draft = (_builderKey.currentState as dynamic)?.exportDraft();
    final pages = (draft is Map) ? (draft['pages'] as List?) : null;
    if (draft == null || pages == null || pages.isEmpty) {
      if (!mounted) return;
      showHonooToast(
        context,
        message: 'Nessun contenuto da pubblicare sulla Luna.',
      );
      return;
    }

    try {
      final HinooDraft hinooDraft = _convertRawBuilderDraft(draft);
      final result = await _controller.sendToMoon(hinooDraft);
      if (!mounted) return;
      final text = result == HinooMoonResult.published
          ? 'Pubblicato sulla Luna.'
          : 'Hinoo già presente sulla Luna.';
      showHonooToast(
        context,
        message: text,
      );
    } catch (e) {
      if (!mounted) return;
      showHonooToast(
        context,
        message: 'Errore: $e',
      );
    }
  }

  // Helpers layout
  double _contentMaxWidth(double w) {
    if (w < 480) return w * 0.94;
    if (w < 768) return w * 0.92;
    if (w < 1024) return w * 0.84;
    if (w < 1440) return w * 0.70;
    return w * 0.58;
  }

  // --- Pulsanti esterni che comandano il builder via GlobalKey ---
  void _deleteCurrentFromBuilder() {
    final dyn = _builderKey.currentState as dynamic;
    if (dyn?.deleteCurrentPagePublic != null) {
      dyn.deleteCurrentPagePublic();
    } else {
      _warnMissingApi('_deleteCurrentFromBuilder → deleteCurrentPagePublic');
    }
  }

  void _triggerDownloadFromBuilder() {
    final dyn = _builderKey.currentState as dynamic;
    if (dyn?.openDownloadDialogPublic != null) {
      dyn.openDownloadDialogPublic();
    } else {
      _warnMissingApi('_triggerDownloadFromBuilder → openDownloadDialogPublic');
    }
  }

  Future<void> _handleDownloadTap() async {
    if (!_hasMinTextForDownload) {
      if (!mounted) return;
      showHonooToast(
        context,
        message: 'Scrivi almeno 1 carattere prima di scaricare',
      );
      return;
    }
    _triggerDownloadFromBuilder();
  }

  void _goToFromBuilder(int index) {
    final dyn = _builderKey.currentState as dynamic;
    if (dyn?.goToPublic != null) {
      dyn.goToPublic(index);
    } else {
      _warnMissingApi('onTapThumb → goToPublic');
    }
  }

  void _addPageFromBuilder() {
    final dyn = _builderKey.currentState as dynamic;
    if (dyn?.addPagePublic != null) {
      dyn.addPagePublic();
    } else {
      _warnMissingApi('onAddPage → addPagePublic');
    }
  }

  void _reorderFromBuilder(int oldIndex, int newIndex) {
    final dyn = _builderKey.currentState as dynamic;
    if (dyn?.reorderPagesPublic != null) {
      dyn.reorderPagesPublic(oldIndex, newIndex);
    } else {
      _warnMissingApi('onReorder → reorderPagesPublic');
    }
  }

  void _warnMissingApi(String what) {
    if (!mounted) return;
    showHonooToast(
      context,
      message: 'Collega API del builder: $what',
    );
  }

  @override
  Widget build(BuildContext context) {
    final double lunaReserve = LunaFissa.reserveTopPadding(context);
    final double extraTop = (lunaReserve - _titleH);
    final double contentTopPadding = extraTop > 0 ? extraTop : 0;

    return Scaffold(
      backgroundColor: HonooColor.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            final double viewW = viewport.maxWidth;
            final double viewH = viewport.maxHeight;
            final double targetMaxW = _contentMaxWidth(viewW);

            // Altezza centrale per canvas = tutto ciò che resta (footer è Positioned)
            final double availableH = (viewH -
                    _titleH // [Riga 1] titolo app
                    -
                    contentTopPadding // spazio riservato per non coprire i bottoni
                    -
                    _controlsH // [Riga 2] bottoni bianchi visibili
                    -
                    _thumbsH // [Riga 4] thumbnails
                    -
                    _footerH // riserva fisica per la navbar/overlay
                )
                .clamp(0.0, double.infinity);

            // Calcolo box 9:16 per [Riga 2]
            const double ar = 9 / 16;
            double canvasW = targetMaxW;
            double canvasH = canvasW / ar;
            if (canvasH > availableH) {
              canvasH = availableH;
              canvasW = canvasH * ar;
            }
            _lastCanvasHeight = canvasH;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // ===== COLONNA PRINCIPALE: 3 righe visive + spazio riservato ====
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // [Riga 1] Titolo/app name
                    SizedBox(
                      height: _titleH,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            Utility().appName,
                            style: GoogleFonts.libreFranklin(
                              color: HonooColor.secondary,
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),

                    // Spazio riservato per non far coprire dalla luna
                    SizedBox(height: contentTopPadding),

                    // [Riga 2] Bottoni bianchi (fissi in alto a destra del canvas)
                    SizedBox(
                      height: _controlsH,
                      child: Center(
                        child: SizedBox(
                          width: canvasW,
                          height: _controlsH,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (_isWriteStep) ...[
                                WhiteIconButton(
                                  tooltip: 'download',
                                  icon: Icons.download_outlined,
                                  onPressed: () => _handleDownloadTap(),
                                ),
                                const SizedBox(width: 12),
                              ],
                              WhiteIconButton(
                                tooltip: 'Elimina pagina',
                                icon: Icons.delete_outline,
                                onPressed: _deleteCurrentFromBuilder,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // [Riga 3] CANVAS 9:16 — HinooBuilder centrato, nessun overlay
                    SizedBox(
                      height: availableH,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: targetMaxW),
                          child: SizedBox(
                            width: canvasW,
                            height: canvasH,
                            child: ClipRect(
                              child: HinooBuilder(
                                key: _builderKey,
                                onHinooChanged: _onHinooChanged,
                                onPngExported: _onPngExported,
                                embedThumbnails: false,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // [Riga 4] THUMBNAILS — usa il tuo widget esterno
                    SizedBox(
                      height: _thumbsH,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        child: AnteprimaHinoo(
                          pages: _pages,
                          currentIndex: _currentIndex,
                          onTapThumb: _goToFromBuilder,
                          onAddPage: _addPageFromBuilder,
                          onReorder: _reorderFromBuilder,
                          canvasHeight: canvasH,
                          fallbackBgUrl: _globalBgUrl,
                          fallbackBgTransform: _globalBgTransform,
                          fallbackBgBytes: _globalBgPreviewBytes,
                        ),
                      ),
                    ),

                    // [Riga 5] Spazio riservato per la navbar (overlay)
                    const SizedBox(height: _footerH),
                  ],
                ),

                // LUNA FISSA (sopra, ma abbiamo riservato spazio → non accavalla)
                const LunaFissa(),

                // ============ FOOTER: Home – Chest – OK/Luna ============ //
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // HOME
                        IconButton(
                          icon: SvgPicture.asset(
                            "assets/icons/home.svg",
                            semanticsLabel: 'Home',
                            colorFilter: const ColorFilter.mode(
                              HonooColor.onBackground,
                              BlendMode.srcIn,
                            ),
                          ),
                          iconSize: 60,
                          splashRadius: 25,
                          tooltip: 'Indietro',
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 24),

                        // CHEST
                        IconButton(
                          icon: SvgPicture.asset("assets/icons/chest.svg",
                              semanticsLabel: 'Chest'),
                          iconSize: 60,
                          splashRadius: 40,
                          tooltip: 'Apri il tuo Cuore',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ChestPage()),
                            );
                          },
                        ),
                        const SizedBox(width: 24),

                        // OK → LUNA
                        _savedToChest
                            ? IconButton(
                                icon: SvgPicture.asset("assets/icons/moon.svg",
                                    semanticsLabel: 'Luna'),
                                iconSize: 32,
                                splashRadius: 25,
                                tooltip: 'Spedisci sulla Luna',
                                onPressed: _submitToMoon,
                              )
                            : IconButton(
                                icon: SvgPicture.asset("assets/icons/ok.svg",
                                    semanticsLabel: 'OK'),
                                iconSize: 60,
                                splashRadius: 25,
                                tooltip: 'Salva hinoo',
                                onPressed: _submitHinoo,
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Pulsante bianco estratto in lib/Widgets/WhiteIconButton.dart
