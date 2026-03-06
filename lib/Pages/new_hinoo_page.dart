// lib/Pages/new_hinoo_page.dart
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:honoo/Services/supabase_provider.dart';

import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Widgets/honoo_dialogs.dart';
import 'package:honoo/Widgets/honoo_app_title.dart';
import 'package:honoo/Widgets/responsive_footer_bar.dart';
import 'package:honoo/Utility/responsive_layout.dart';

import 'package:honoo/Controller/hinoo_controller.dart';
import 'package:honoo/UI/hinoo_typography.dart';

import '../UI/hinoo_builder.dart';

import 'chest_page.dart';
import 'email_login_page.dart';
import 'home_page.dart';
import 'placeholder_page.dart';
import '../Entities/hinoo.dart';
import 'casa_builder_page.dart';

class NewHinooPage extends StatefulWidget {
  const NewHinooPage({
    super.key,
    this.isReply = false,
    this.isCampanello = false,
    this.forcedType,
    this.recipientTag,
    this.returnSavedId = false,
    this.replyTo,
    this.conversationId,
  });

  final bool isReply;
  final bool isCampanello;
  final HinooType? forcedType;
  final String? recipientTag;
  final bool returnSavedId;
  final String? replyTo;
  final String? conversationId;

  @override
  State<NewHinooPage> createState() => _NewHinooPageState();
}

class _NewHinooPageState extends State<NewHinooPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey _builderKey = GlobalKey();

  final _controller = HinooController();
  bool _savedToChest = false;
  late final AnimationController _chestBounceController;
  late final Animation<double> _chestBounce;

  double _lastCanvasHeight = 0;
  String _builderStep = 'changeBg';
  int _currentTextLength = 0;
  bool _bgUploadInProgress = false;

  // ✅ nuovo: vero se c'è uno sfondo immagine (locale o url)
  bool _hasBgImage = false;

  bool get _isWriteStep => _builderStep == 'writeText';
  bool get _hasMinTextForDownload => _currentTextLength >= 1;

  static const double _titleH = 65;

  @override
  void initState() {
    super.initState();
    _chestBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _chestBounce = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.18)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.18, end: 0.95)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.95, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_chestBounceController);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dyn = _builderKey.currentState as dynamic;
      final draft = dyn?.exportDraft?.call();
      if (!mounted) return;
      setState(() => _applyDraftToLocalState(draft));
    });
  }

  @override
  void dispose() {
    _chestBounceController.dispose();
    super.dispose();
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

    // ✅ Determina se c’è uno sfondo immagine
    final bool hasBgFlag = draft['hasBg'] == true;
    final bool hasPreviewBytes = draft['bgPreviewBytes'] != null;
    final dynamic bgUrlRaw = draft['bgUrl'];
    final bool hasBgUrl = bgUrlRaw is String && bgUrlRaw.trim().isNotEmpty;

    _hasBgImage = hasBgFlag || hasPreviewBytes || hasBgUrl;
  }

  Future<void> _onPngExported(Uint8List bytes) async {
    if (!mounted) return;
    showHonooToast(context,
        message: 'PNG generato: pronto per salvare o condividere.');
  }

  Future<void> _submitHinoo() async {
    const String writeHint =
        'Carica prima la tua immagine\n conferma con \u2713\n e poi scrivi il tuo testo';
    final dynamic rawDraft =
        (_builderKey.currentState as dynamic)?.exportDraft();
    final pages = (rawDraft is Map) ? (rawDraft['pages'] as List?) : null;
    if (rawDraft == null || pages == null || pages.isEmpty) {
      if (!mounted) return;
      showHonooToast(
        context,
        message: writeHint,
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
          title: 'Devi accedere prima',
          message:
              'Per salvare questo hinoo,\ndevi fare prima il login.\nVuoi andare alla pagina di login?',
          confirmLabel: 'Vai al login',
        ),
      );

      if (goLogin == true && mounted) {
        // ✅ aspetta il risultato, ma NON salvare in automatico
        final ok = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => EmailLoginPage(
              pendingHinooDraft: hinooDraft.toJson(),
            ),
          ),
        );

        if (!mounted) return;

        if (ok == true) {
          showHonooToast(
            context,
            message: 'Accesso completato. Ora puoi salvare lo hinoo.',
          );
        }
      }
      return;
    }

// Se il builder sta ancora caricando lo sfondo, fermati
    if (rawDraft['isUploadingBg'] == true || _bgUploadInProgress) {
      if (!mounted) return;
      showHonooToast(
        context,
        message: 'Attendi il caricamento dello sfondo prima di continuare.',
      );
      return;
    }

// ✅ SALVATAGGIO OGGETTO: bgUrl obbligatorio (persistenza)
// (La preview serve per download/UX, ma non basta per creare l'oggetto persistente)
    final bool missingPersistedBg = hinooDraft.pages.any(
      (slide) =>
          slide.backgroundImage == null || slide.backgroundImage!.isEmpty,
    );

    if (missingPersistedBg) {
      if (!mounted) return;
      showHonooToast(
        context,
        message:
            'Per salvare l\'hinoo nello Scrigno,\n premi ✓\n e conferma prima\n il caricamento dell\'immagine.',
      );
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
      final bool hasPreview = rawDraft['bgPreviewBytes'] != null;

      //  se ho preview, l'immagine ESISTE → NON errore
      if (hasPreview) {
        // qui non fare nulla: l'utente può
        // - salvare più tardi
        // - oppure scaricare
      } else {
        // ❌ qui sì: manca davvero lo sfondo
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
      // Se manca il testo, mostra l'hint invece del dialog/testo generico
      final hasMissingText =
          validationErrors.any((e) => e.toLowerCase().contains('testo'));
      if (hasMissingText) {
        showHonooToast(context, message: writeHint);
      } else {
        final errorText = 'Bozza non valida:\n- ${validationErrors.join('\n- ')}';
        showHonooToast(context, message: errorText);
      }
      return;
    }

    try {
      if (widget.returnSavedId) {
        final hinooId = await _controller.saveToChestAndReturnId(hinooDraft);
        if (!mounted) return;
        showHonooToast(context, message: 'hinoo salvato.');
        Navigator.of(context).pop(hinooId);
        return;
      }

      if (widget.isCampanello) {
        final hinooId = await _controller.saveToChestAndReturnId(hinooDraft);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => CasaBuilderPage(campanelloHinooId: hinooId),
          ),
        );
        return;
      }

      await _controller.saveToChest(hinooDraft);
      if (!mounted) return;
      setState(() => _savedToChest = true);
      _chestBounceController.forward(from: 0);
      final bool isAnswer = (hinooDraft.type == HinooType.answer) || widget.isReply;
      if (isAnswer) {
        showHonooToast(
          context,
          message:
              "L'hinoo adesso è nel tuo Scrigno,\n e,\n soprattutto,\n nello Scrigno di qualcun altro.",
        );
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChestPage(
              focusReplies: true,
              focusConversationId: widget.conversationId,
              highlightLatest: true,
            ),
          ),
        );
        return;
      }
      if (!widget.isReply && !widget.isCampanello) {
        final bool? sendToMoon = await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (_) => const HonooConfirmDialog(
            title: "L'hinoo è stato salvato nel tuo Scrigno.",
            message:
                'Vuoi spedirlo anche sulla Luna, per mostrarlo a tutti?',
            confirmLabel: 'Sì',
            cancelLabel: 'No',
          ),
        );
        if (sendToMoon == true && mounted) {
          try {
            final result = await _controller.sendToMoon(hinooDraft);
            if (!mounted) return;
            final text = result == HinooMoonResult.published
                ? "L'hinoo è anche sulla Luna."
                : 'hinoo già presente sulla Luna.';
            showHonooToast(context, message: text);
          } catch (e) {
            if (!mounted) return;
            showHonooToast(context, message: 'Errore: $e');
          }
        }
      }

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

    final HinooType type = widget.forcedType ??
        (widget.isCampanello
            ? HinooType.answer
            : (widget.isReply ? HinooType.answer : HinooType.personal));

    return HinooDraft(
      pages: slides,
      type: type,
      recipientTag: widget.recipientTag,
      replyTo: widget.replyTo,
      conversationId: widget.conversationId,
      baseCanvasHeight: _lastCanvasHeight > 0 ? _lastCanvasHeight : null,
    );
  }

  // rimosso: submit to moon non più utilizzato in questa pagina

  double _contentMaxWidth(double w) {
    return w;
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
          title: 'Devi accedere prima',
          message:
              'Per scaricare questo hinoo,\ndevi fare prima il login.\nVuoi andare alla pagina di login?',
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

  Widget _buildCanvasControls() {
    const double iconSize = 22;
    const double buttonBox = 34;
    const double pillHeight = 40;

    Widget iconBtn({
      required IconData icon,
      required String tooltip,
      required VoidCallback onPressed,
    }) {
      return SizedBox(
        width: buttonBox,
        height: buttonBox,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon, size: iconSize, color: Colors.white),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          splashRadius: buttonBox / 2,
          visualDensity: VisualDensity.compact,
        ),
      );
    }

    final controls = Container(
      height: pillHeight,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(pillHeight / 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_isWriteStep) ...[
            iconBtn(
              tooltip: 'Salva sul dispositivo',
              icon: Icons.download_outlined,
              onPressed: _handleDownloadTap,
            ),
            const SizedBox(width: 6),
          ],
          iconBtn(
            tooltip: 'Cancella hinoo',
            icon: Icons.delete_outline,
            onPressed: _deleteCurrentFromBuilder,
          ),
        ],
      ),
    );

    if (_hasBgImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(pillHeight / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: controls,
        ),
      );
    }

    return controls;
  }

  @override
  Widget build(BuildContext context) {
    const double contentTopPadding = 0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: HonooColor.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            final double keyboard = MediaQuery.of(context).viewInsets.bottom;
            final bool kbOpen = keyboard > 0;
            final double safeBottom = MediaQuery.of(context).viewPadding.bottom;

            final double viewW = viewport.maxWidth;
            final double viewH = viewport.maxHeight;
            final double targetMaxW = _contentMaxWidth(viewW);
            final ResponsiveLayoutMode layoutMode =
                ResponsiveLayout.modeForWidth(viewW);
            final double footerIconSize =
                ResponsiveLayout.footerIconSizeForMode(layoutMode);
            final double footerGap =
                ResponsiveLayout.footerGapForMode(layoutMode);
            final double footerBottomPadding =
                ResponsiveLayout.footerBottomPaddingForMode(layoutMode);
            final double footerSpacing = footerBottomPadding + safeBottom;
            final double footerTopSpacing = footerSpacing / 2;
            final double footerBottomSpacing =
                footerSpacing - footerTopSpacing;
            final double footerReserved =
                footerIconSize + footerTopSpacing + footerBottomSpacing;

            final double availableH =
                (viewH -
                        _titleH -
                        contentTopPadding -
                        footerReserved)
                    .clamp(0.0, double.infinity);

            const double ar = 9 / 16;
            double canvasW = targetMaxW;
            double canvasH = canvasW / ar;
            if (canvasH > availableH) {
              canvasH = availableH;
              canvasW = canvasH * ar;
            }
            _lastCanvasHeight = HinooTypography.baselineCanvasHeight;

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
                const SizedBox(height: contentTopPadding),
                SizedBox(
                  height: availableH,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: targetMaxW),
                      child: SizedBox(
                        width: canvasW,
                        height: canvasH,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRect(
                                child: HinooBuilder(
                                  key: _builderKey,
                                  onHinooChanged: _onHinooChanged,
                                  onPngExported: _onPngExported,
                                  hintText:
                                      'Carica prima la tua immagine\n conferma con \u2713\n e poi scrivi il tuo testo',
                                  backgroundPromptText: widget.isCampanello
                                      ? 'Scrivi qui\n'
                                          'tutto quello che vuoi\n'
                                          'per la pagina\n'
                                          'del tuo campanello'
                                      : null,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: _buildCanvasControls(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: footerReserved),
              ],
            );

            final Widget content = kbOpen
                ? SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.manual,
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
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    ignoring: kbOpen,
                    child: ResponsiveFooterBar(
                      bottomPadding: footerBottomSpacing,
                      desiredGap: footerGap,
                      minGap: 16,
                      height: footerIconSize,
                      actions: [
                        ResponsiveFooterAction(
                          asset: "assets/icons/home.svg",
                          semanticsLabel: 'Home',
                          colorFilter: const ColorFilter.mode(
                            HonooColor.onBackground,
                            BlendMode.srcIn,
                          ),
                          size: footerIconSize,
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
                        ResponsiveFooterAction(
                          asset: "assets/icons/chest.svg",
                          semanticsLabel: 'Chest',
                          size: footerIconSize,
                          splashRadius: 40,
                          tooltip: 'Apri il tuo Cuore',
                          icon: AnimatedBuilder(
                            animation: _chestBounce,
                            builder: (context, child) => Transform.scale(
                              scale: _chestBounce.value,
                              child: child,
                            ),
                            child: SvgPicture.asset(
                              "assets/icons/chest.svg",
                              width: footerIconSize,
                              height: footerIconSize,
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ChestPage()),
                            );
                          },
                        ),
                        ResponsiveFooterAction(
                          asset: "assets/icons/ok.svg",
                          semanticsLabel: ((widget.isReply || widget.forcedType == HinooType.answer)
                                  ? 'Invia'
                                  : (widget.isCampanello ? 'Salva il campanello' : 'OK')),
                          size: footerIconSize,
                          splashRadius: 25,
                          tooltip: (widget.isReply || widget.forcedType == HinooType.answer)
                              ? 'Invia'
                              : (widget.isCampanello
                                  ? 'Salva il campanello'
                                  : 'Salva hinoo'),
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
