// lib/Pages/new_hinoo_page.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:honoo/Services/supabase_provider.dart';

import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Widgets/luna_fissa.dart';
import 'package:honoo/Widgets/honoo_dialogs.dart';
import 'package:honoo/Widgets/honoo_app_title.dart';

import 'package:honoo/Controller/hinoo_controller.dart';

import '../UI/hinoo_builder.dart';
import '../Widgets/white_icon_button.dart';

import 'chest_page.dart';
import 'email_login_page.dart';
import 'home_page.dart';
import 'placeholder_page.dart';
import '../Entities/hinoo.dart';

class NewHinooPage extends StatefulWidget {
  const NewHinooPage({super.key});

  @override
  State<NewHinooPage> createState() => _NewHinooPageState();
}

class _NewHinooPageState extends State<NewHinooPage> {
  final GlobalKey _builderKey = GlobalKey();

  final _controller = HinooController();
  bool _savedToChest = false;

  double _lastCanvasHeight = 0;
  String _builderStep = 'changeBg';
  int _currentTextLength = 0;
  bool _bgUploadInProgress = false;

  bool get _isWriteStep => _builderStep == 'writeText';
  bool get _hasMinTextForDownload => _currentTextLength >= 1;

  static const double _titleH = 52;
  static const double _controlsH = 44;
  static const double _footerH = 100.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dyn = _builderKey.currentState as dynamic;
      final draft = dyn?.exportDraft?.call();
      if (!mounted) return;
      setState(() => _applyDraftToLocalState(draft));
    });
  }

  void _onHinooChanged(dynamic draft) {
    setState(() {
      if (_savedToChest) _savedToChest = false;
      _applyDraftToLocalState(draft);
    });
  }

  void _applyDraftToLocalState(dynamic draft) {
    if (draft is! Map) return;

    final dynamic ch = draft['canvasHeight'];
    if (ch is num) _lastCanvasHeight = ch.toDouble();

    final dynamic rawStep = draft['step'];
    if (rawStep is String && rawStep.isNotEmpty) {
      _builderStep = rawStep;
    }

    _bgUploadInProgress = draft['isUploadingBg'] == true;

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

  Future<void> _onPngExported(Uint8List bytes) async {
    if (!mounted) return;
    showHonooToast(context,
        message: 'PNG generato: pronto per salvare o condividere.');
  }

  Future<void> _submitHinoo() async {
    final dynamic rawDraft =
        (_builderKey.currentState as dynamic)?.exportDraft();
    final pages = (rawDraft is Map) ? (rawDraft['pages'] as List?) : null;
    if (rawDraft == null || pages == null || pages.isEmpty) {
      if (!mounted) return;
      showHonooToast(
        context,
        message: 'Completa il tuo hinoo caricando l’immagine e il testo.',
      );
      return;
    }

    final HinooDraft hinooDraft = _convertRawBuilderDraft(rawDraft);

    final user = SupabaseProvider.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      final bool? goLogin = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (_) => const HonooConfirmDialog(
          title: 'Devi accedere',
          message:
              'Per salvare questo hinoo, devi fare prima il log in. Vuoi andare alla pagina di login?',
          confirmLabel: 'Vai al login',
        ),
      );
      if (goLogin == true && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                EmailLoginPage(pendingHinooDraft: hinooDraft.toJson()),
          ),
        );
      }
      return;
    }

    if (rawDraft['isUploadingBg'] == true || _bgUploadInProgress) {
      if (!mounted) return;
      showHonooToast(
        context,
        message: 'Attendi il caricamento dello sfondo prima di continuare.',
      );
      return;
    }

    final bool hasMissingBg = hinooDraft.pages.any(
      (slide) =>
          (slide.backgroundImage == null || slide.backgroundImage!.isEmpty),
    );
    if (hasMissingBg) {
      final bool hadLocalBg = (rawDraft['hasBg'] as bool?) ?? false;
      final bool hadPreview = rawDraft['bgPreviewBytes'] != null;
      if (hadLocalBg || hadPreview) {
        if (!mounted) return;
        showHonooToast(
          context,
          message:
              'Non siamo riusciti a salvare lo sfondo. Riprova a caricare l\'immagine.',
        );
        return;
      }
    }

    final validationErrors = _controller.validateDraft(hinooDraft);
    if (validationErrors.isNotEmpty) {
      if (!mounted) return;
      final errorText = 'Bozza non valida:\n- ${validationErrors.join('\n- ')}';
      showHonooToast(context, message: errorText);
      return;
    }

    try {
      await _controller.saveToChest(hinooDraft);
      if (!mounted) return;
      setState(() => _savedToChest = true);
      showHonooToast(context, message: 'salvato nello Scrigno.');
    } catch (e) {
      if (!mounted) return;
      showHonooToast(context, message: 'Errore: $e');
    }
  }

  HinooDraft _convertRawBuilderDraft(Map raw) {
    final List<dynamic> rawPages = (raw['pages'] as List<dynamic>? ?? []);
    final List<HinooSlide> slides = [];

    for (final p in rawPages) {
      if (p is Map) {
        final bgUrl = p['bgUrl'] as String?;
        final txt = ((p['text'] as String?) ?? '').trim();
        final textColorVal = (p['textColor'] as int?) ?? 0xFFFFFFFF;
        final isTextWhite = textColorVal == const Color(0xFFFFFFFF).value;

        double scale = 1.0;
        double offX = 0.0;
        double offY = 0.0;
        List<double>? normalizedTransform;

        final tr = p['bgTransform'];
        if (tr is List && tr.length == 16) {
          final List<double> m = tr.map((e) => (e as num).toDouble()).toList();
          scale = m[0];

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
      showHonooToast(context,
          message: 'Nessun contenuto da pubblicare sulla Luna.');
      return;
    }

    try {
      final HinooDraft hinooDraft = _convertRawBuilderDraft(draft);
      final result = await _controller.sendToMoon(hinooDraft);
      if (!mounted) return;
      final text = result == HinooMoonResult.published
          ? 'Pubblicato sulla Luna.'
          : 'hinoo già presente sulla Luna.';
      showHonooToast(context, message: text);
    } catch (e) {
      if (!mounted) return;
      showHonooToast(context, message: 'Errore: $e');
    }
  }

  double _contentMaxWidth(double w) {
    if (w < 480) return w * 0.94;
    if (w < 768) return w * 0.92;
    if (w < 1024) return w * 0.84;
    if (w < 1440) return w * 0.70;
    return w * 0.58;
  }

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
      showHonooToast(context,
          message: 'Scrivi almeno 1 carattere prima di scaricare');
      return;
    }

    final user = SupabaseProvider.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      final bool? goLogin = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (_) => const HonooConfirmDialog(
          title: 'Devi accedere',
          message:
              'Per scaricare questo hinoo, devi fare prima il log in. Vuoi andare alla pagina di login?',
          confirmLabel: 'Vai al login',
        ),
      );
      if (goLogin == true && mounted) {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const EmailLoginPage()));
      }
      return;
    }

    _triggerDownloadFromBuilder();
  }

  void _warnMissingApi(String what) {
    if (!mounted) return;
    showHonooToast(context, message: 'Collega API del builder: $what');
  }

  @override
  Widget build(BuildContext context) {
    final double lunaReserve = LunaFissa.reserveTopPadding(context);
    final double extraTop = (lunaReserve - _titleH);
    final double contentTopPadding = extraTop > 0 ? extraTop : 0;

    return Scaffold(
      // ✅ tastiera “overlay”: non ridimensiona la pagina
      resizeToAvoidBottomInset: false,
      backgroundColor: HonooColor.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            final double keyboard = MediaQuery.of(context).viewInsets.bottom;
            final bool kbOpen = keyboard > 0;

            final double viewW = viewport.maxWidth;
            final double viewH = viewport.maxHeight; // ✅ stabile su web
            final double targetMaxW = _contentMaxWidth(viewW);

            final double availableH =
                (viewH - _titleH - contentTopPadding - _controlsH - _footerH)
                    .clamp(0.0, double.infinity);

            const double ar = 9 / 16;
            double canvasW = targetMaxW;
            double canvasH = canvasW / ar;
            if (canvasH > availableH) {
              canvasH = availableH;
              canvasW = canvasH * ar;
            }
            _lastCanvasHeight = canvasH;

            // ✅ Colonna principale: scrollabile SOLO quando kb aperta
            final Widget mainColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: _titleH,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                    child: Align(
                      alignment: Alignment.center,
                      child: HonooAppTitle(
                        onTap: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const PlaceholderPage()),
                            (route) => false,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(height: contentTopPadding),

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
                              onPressed: _handleDownloadTap,
                            ),
                            const SizedBox(width: 12),
                          ],
                          WhiteIconButton(
                            tooltip: 'Svuota hinoo',
                            icon: Icons.delete_outline,
                            onPressed: _deleteCurrentFromBuilder,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

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
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // spazio “fisico” per il footer (che resta overlay nello Stack)
                const SizedBox(height: _footerH),
              ],
            );

            final Widget content = kbOpen
                ? SingleChildScrollView(
                    // ✅ NON dismissare la tastiera con scroll
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.manual,
                    // ✅ aggiungo spazio extra per scrollare anche con kb sopra
                    padding: EdgeInsets.only(bottom: keyboard),
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: viewH),
                      child: mainColumn,
                    ),
                  )
                : mainColumn;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                content,

                const LunaFissa(),

                // Footer overlay: disattivato con kb aperta per non rubare tocchi
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    ignoring: kbOpen,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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
                              tooltip: 'Home',
                              onPressed: () {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (_) => const HomePage()),
                                  (route) => false,
                                );
                              },
                            ),
                            const SizedBox(width: 24),
                            IconButton(
                              icon: SvgPicture.asset(
                                "assets/icons/chest.svg",
                                semanticsLabel: 'Chest',
                              ),
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
                            _savedToChest
                                ? IconButton(
                                    icon: SvgPicture.asset(
                                      "assets/icons/moon.svg",
                                      semanticsLabel: 'Luna',
                                    ),
                                    iconSize: 32,
                                    splashRadius: 25,
                                    tooltip: 'Spedisci sulla Luna',
                                    onPressed: _submitToMoon,
                                  )
                                : IconButton(
                                    icon: SvgPicture.asset(
                                      "assets/icons/ok.svg",
                                      semanticsLabel: 'OK',
                                    ),
                                    iconSize: 60,
                                    splashRadius: 25,
                                    tooltip: 'Salva hinoo',
                                    onPressed: _submitHinoo,
                                  ),
                          ],
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
    );
  }
}
