import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Services/supabase_provider.dart';

import '../Entities/honoo.dart';
import '../Services/honoo_image_uploader.dart';
import '../UI/honoo_builder.dart';
import 'package:honoo/Services/honoo_service.dart';

import 'email_login_page.dart';
import 'chest_page.dart';
import 'new_hinoo_page.dart';
import 'home_page.dart';
import '../Widgets/honoo_dialogs.dart';
import '../Widgets/honoo_app_title.dart';
import '../UI/HonooBuilder/dialogs/name_honoo_dialog.dart';
import 'placeholder_page.dart';
import '../Utility/responsive_layout.dart';
import '../Widgets/responsive_footer_bar.dart';
import 'package:uuid/uuid.dart';

class NewHonooPage extends StatefulWidget {
  const NewHonooPage({
    super.key,
    this.forcedType,
    this.recipientTag,
    this.returnSavedId = false,
    this.conversationId,
    this.replyTo,
  });

  final HonooType? forcedType;
  final String? recipientTag;
  final bool returnSavedId;
  final String? conversationId;
  final String? replyTo;

  @override
  State<NewHonooPage> createState() => _NewHonooPageState();
}

class _NewHonooPageState extends State<NewHonooPage> {
  final GlobalKey<HonooBuilderState> _builderKey =
      GlobalKey<HonooBuilderState>();

  double? _initialViewH;

  String _text = '';
  String _imageUrl = '';

  /// cache dell’URL immagine definitiva (dopo upload/risoluzione)
  String? _finalImageUrlCache;

  /// contenuto effettivamente SALVATO (per evitare reset dello stato da update identici)
  String _lastSavedRawImage = '';
  bool _hasMinTextForDownload = false;

  bool get _hasImageForDownload => _imageUrl.trim().isNotEmpty;
  bool get _shouldShowCanvasControls =>
      _hasMinTextForDownload || _hasImageForDownload;

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

    return ClipRRect(
      borderRadius: BorderRadius.circular(pillHeight / 2),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
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
              iconBtn(
                tooltip: 'Salva sul dispositivo',
                icon: Icons.download_outlined,
                onPressed: _handleDownloadTap,
              ),
              const SizedBox(width: 6),
              iconBtn(
                tooltip: 'Cancella honoo',
                icon: Icons.delete_outline,
                onPressed: _handleDeleteTap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Aggiorna solo se cambia DAVVERO e non è identico all’ultimo SALVATO.
  void _onHonooChanged(String text, String imageUrl) {
    // se identico allo stato attuale → nessun rebuild inutile
    if (text == _text && imageUrl == _imageUrl) return;

    setState(() {
      _text = text;
      _imageUrl = imageUrl;

      _hasMinTextForDownload = text.trim().isNotEmpty;

      // resetta eventuali indicatori se il contenuto è DIVERSO da quello salvato

      // se cambia l’immagine rispetto a QUELLA SALVATA, invalida cache
      if (imageUrl != _lastSavedRawImage) {
        _finalImageUrlCache = null;
      }
    });
  }

  Future<void> _submitHonoo() async {
    final user = SupabaseProvider.client.auth.currentUser;

    // 1) Se non sei loggato: vai al login e torna qui (senza auto-salvare)
    if (user == null) {
      if (!mounted) return;

      final bool? goLogin = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (_) => const HonooConfirmDialog(
          title: 'Devi prima accedere',
          message: '\nVuoi andare alla pagina di login?',
          confirmLabel: 'Vai al login',
        ),
      );

      if (goLogin != true || !mounted) return;

      // ✅ aspetta la fine del login
      final bool? ok = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => EmailLoginPage(
            pendingHonooText: _text,
            pendingImageUrl: _imageUrl,
          ),
        ),
      );

      if (!mounted) return;

      // ✅ niente auto-save: solo feedback opzionale
      if (ok == true) {
        showHonooToast(
          context,
          message: 'Accesso completato. Premi di nuovo OK per salvare.',
        );
      }

      return;
    }

    // 2) Validazioni minime (testo + immagine)
    if (_text.trim().isEmpty) {
      if (!mounted) return;
      showHonooToast(context, message: 'Scrivi qualcosa prima di salvare.');
      return;
    }

    if (_imageUrl.trim().isEmpty) {
      if (!mounted) return;
      showHonooToast(context, message: 'Carica un’immagine prima di salvare.');
      return;
    }

    // 3) Risolvi URL definitivo (usa cache se già risolto)
    final String? finalImageUrl =
        _finalImageUrlCache ?? await _resolveFinalImageUrl(_imageUrl);

    if (finalImageUrl == null || finalImageUrl.isEmpty) {
      if (!mounted) return;
      showHonooToast(
        context,
        message: 'Immagine non valida. Ricaricala e riprova.',
      );
      return;
    }

    // 4) Crea e salva
    final HonooType type = widget.forcedType ?? HonooType.personal;
    // conversation: se risposta usa quella fornita; altrimenti genera una nuova
    final String conversationId = widget.conversationId ?? const Uuid().v4();
    final newHonoo = Honoo(
      0,
      _text,
      finalImageUrl,
      DateTime.now().toIso8601String(),
      DateTime.now().toIso8601String(),
      user.id,
      type,
      widget.replyTo,
      widget.recipientTag,
    )..conversationId = conversationId;

    try {
      if (widget.returnSavedId) {
        final id = await HonooService.publishHonooAndReturnId(newHonoo);
        if (!mounted) return;
        showHonooToast(context, message: 'honoo salvato.');
        Navigator.of(context).pop(id);
        return;
      }

      await HonooService.publishHonoo(newHonoo);

      if (!mounted) return;
      setState(() {
        _finalImageUrlCache = finalImageUrl;
        _lastSavedRawImage = _imageUrl;
      });

      if (type == HonooType.answer) {
        // Risposta: messaggio dedicato e vai allo Scrigno con focus conversazione + sobbalzo
        showHonooToast(
          context,
          message:
              "L'honoo adesso è nel tuo Scrigno, e, soprattutto nello Scrigno di quacun altro.",
        );
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChestPage(
              focusReplies: true,
              focusConversationId: conversationId,
              highlightLatest: true,
            ),
          ),
        );
        return;
      } else {
        final bool? sendToMoon = await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (_) => const HonooConfirmDialog(
            title: "L'honoo è stato salvato nel tuo Scrigno.",
            message: 'Vuoi spedirlo anche sulla Luna, per mostrarlo a tutti?',
            confirmLabel: 'Sì',
            cancelLabel: 'No',
          ),
        );
        if (sendToMoon == true && mounted) {
          final sent = await _submitToMoon();
          if (sent && mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomePage()),
              (route) => false,
            );
          }
        }
      }
    } catch (e, st) {
      debugPrint('publishHonoo failed: $e\n$st');
      if (!mounted) return;
      showHonooToast(context, message: 'Errore: $e');
    }
  }

  Future<bool> _submitToMoon() async {
    try {
      final String? finalImageUrl =
          _finalImageUrlCache ?? await _resolveFinalImageUrl(_imageUrl);

      final honooForMoon = Honoo(
        0,
        _text,
        finalImageUrl ?? '',
        DateTime.now().toIso8601String(),
        DateTime.now().toIso8601String(),
        SupabaseProvider.client.auth.currentUser?.id ?? '',
        HonooType.personal,
        null,
        null,
      );

      final ok = await HonooService.duplicateToMoon(honooForMoon);

      if (!mounted) return false;
      showHonooToast(
        context,
        message:
            ok ? "L'honoo è anche sulla Luna." : 'Già presente sulla Luna.',
      );
      return true;
    } catch (e, st) {
      debugPrint('duplicateToMoon failed: $e\n$st');
      if (mounted) {
        showHonooToast(
          context,
          message: 'Errore: $e',
        );
      }
      return false;
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

    final state = _builderKey.currentState;
    if (state == null) {
      showHonooToast(
        context,
        message: 'Impossibile avviare il download.',
      );
      return;
    }

    if (!state.hasImage) {
      showHonooToast(
        context,
        message: "Inserisci prima un'immagine",
      );
      return;
    }

    final user = SupabaseProvider.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      final bool? goLogin = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (_) => const HonooConfirmDialog(
          title: 'Devi prima accedere',
          message: '\nVuoi andare alla pagina di login?',
          confirmLabel: 'Vai al login',
        ),
      );
      if (goLogin == true && mounted) {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const EmailLoginPage()));
      }
      return;
    }

    final String? desiredName = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => NameHonooDialog(initialValue: _defaultHonooFileName()),
    );
    final String? trimmed = desiredName?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return;
    }

    if (!mounted) return;
    await state.downloadHonooPublic(context, fileName: trimmed);
  }

  Future<void> _handleDeleteTap() async {
    final bool? confirmed = await showHonooDeleteDialog(
      context,
      target: HonooDeletionTarget.page,
    );
    if (!mounted) return;
    if (confirmed != true) return;

    _builderKey.currentState?.resetContent();

    setState(() {
      _text = '';
      _imageUrl = '';
      // no-op
      _finalImageUrlCache = null;
      _lastSavedRawImage = '';
      _hasMinTextForDownload = false;
    });
  }

  void _onBuilderFocusChanged(bool hasFocus) {
    if (mounted) setState(() {});
  }

  Future<String?> _resolveFinalImageUrl(String raw) async {
    final s = raw.trim();
    if (s.isEmpty) return null;

    if (s.startsWith('http://') || s.startsWith('https://')) return s;

    if (kIsWeb && s.startsWith('blob:')) {
      if (mounted) {
        showHonooToast(
          context,
          message: 'Immagine locale (blob) non caricabile dal browser.',
        );
      }
      return null;
    }

    final uploaded = await HonooImageUploader.uploadImageFromPath(s);
    return uploaded;
  }

  String _defaultHonooFileName() {
    final String text = _text.trim();
    if (text.isEmpty) return 'honoo';
    final String slug = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp('_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    if (slug.isEmpty) return 'honoo';
    return slug.length > 32 ? slug.substring(0, 32) : slug;
  }

  @override
  Widget build(BuildContext context) {
    // Header compatto per ridurre il gap sopra l’honoo
    const double headerH = 52;
    final double safeBottom = MediaQuery.of(context).viewPadding.bottom;

    const double contentTopPadding = 0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: HonooColor.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            final double viewW = viewport.maxWidth;

            _initialViewH ??= viewport.maxHeight;
            final double viewH = _initialViewH!;

            final ResponsiveLayoutMode layoutMode =
                ResponsiveLayout.modeForWidth(viewW);
            final double targetMaxW =
                ResponsiveLayout.contentMaxWidthForMode(layoutMode, viewW);
            final double footerIconSize =
                ResponsiveLayout.footerIconSizeForMode(layoutMode);
            final double footerGap =
                ResponsiveLayout.footerGapForMode(layoutMode);
            final double footerBottomPadding =
                ResponsiveLayout.footerBottomPaddingForMode(layoutMode);
            final double footerContentH = footerIconSize;
            final double footerSpacing = footerBottomPadding + safeBottom;
            final double footerTopSpacing = footerSpacing / 2;
            final double footerBottomSpacing = footerSpacing - footerTopSpacing;

            // Altezza riservata al footer (3 pulsanti)
            final double footerReserved =
                footerContentH + footerTopSpacing + footerBottomSpacing;

            // Altezza disponibile per il box honoo
            final double availableH =
                (viewH - headerH - contentTopPadding - footerReserved)
                    .clamp(0.0, double.infinity);

            final HonooBuilderMetrics metrics =
                ResponsiveLayout.honooBuilderMetrics(
              availableHeight: availableH,
              maxWidth: targetMaxW,
              mode: layoutMode,
            );
            final double builderWidth = metrics.width;
            final double builderHeight = metrics.height;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // ===== HEADER + HONOO (full height) =====
                Column(
                  children: [
                    SizedBox(
                      height: headerH,
                      child: Center(
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
                    const SizedBox(height: contentTopPadding),
                    SizedBox(
                      height: availableH,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 90),
                          curve: Curves.easeOutCubic,
                          constraints: BoxConstraints(maxWidth: targetMaxW),
                          child: SizedBox(
                            width: builderWidth,
                            height: builderHeight,
                            child: Stack(
                              children: [
                                ClipRect(
                                  child: HonooBuilder(
                                    key: _builderKey,
                                    onHonooChanged: _onHonooChanged,
                                    onFocusChanged: _onBuilderFocusChanged,
                                    imageConfirmIconDisplaySize: footerIconSize,
                                  ),
                                ),
                                if (_shouldShowCanvasControls)
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
                  ],
                ),

                // ===== FOOTER: Home – Chest – (OK|Luna) =====
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ResponsiveFooterBar(
                    bottomPadding: footerBottomSpacing,
                    desiredGap: footerGap,
                    minGap: 16,
                    height: footerContentH,
                    lockGapWhenPossible: true,
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
                            MaterialPageRoute(builder: (_) => const HomePage()),
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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ChestPage()),
                          );
                        },
                      ),
                      ResponsiveFooterAction(
                        asset: "assets/icons/ok.svg",
                        semanticsLabel: (widget.forcedType == HonooType.answer)
                            ? 'Invia'
                            : 'OK',
                        size: footerIconSize,
                        splashRadius: 25,
                        tooltip: (widget.forcedType == HonooType.answer)
                            ? 'Invia'
                            : 'Salva honoo',
                        onPressed: _submitHonoo,
                      ),
                      ResponsiveFooterAction(
                        asset: "assets/icons/piuma.svg",
                        semanticsLabel: 'Piuma',
                        size: footerIconSize,
                        splashRadius: 25,
                        tooltip: 'Scrivi hinoo',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const NewHinooPage()),
                          );
                        },
                      ),
                    ],
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
