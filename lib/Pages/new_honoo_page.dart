import 'package:flutter/foundation.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Services/supabase_provider.dart';

import '../Entities/honoo.dart';
import '../Services/honoo_image_uploader.dart';
import '../UI/honoo_builder.dart';
import 'package:honoo/Services/honoo_service.dart';

import '../Widgets/luna_fissa.dart';
import 'email_login_page.dart';
import 'chest_page.dart';
import 'new_hinoo_page.dart';
import 'home_page.dart';
import '../Widgets/white_icon_button.dart';
import '../Widgets/honoo_dialogs.dart';
import '../Widgets/honoo_app_title.dart';
import '../UI/HonooBuilder/dialogs/name_honoo_dialog.dart';
import 'placeholder_page.dart';
import '../Utility/responsive_layout.dart';
import '../Widgets/responsive_footer_bar.dart';

class NewHonooPage extends StatefulWidget {
  const NewHonooPage({super.key});

  @override
  State<NewHonooPage> createState() => _NewHonooPageState();
}

class _NewHonooPageState extends State<NewHonooPage> {
  final GlobalKey<HonooBuilderState> _builderKey =
      GlobalKey<HonooBuilderState>();

  double? _initialViewH;

  String _text = '';
  String _imageUrl = '';

  /// stato: dopo salvataggio nello scrigno il bottone diventa “luna”
  bool _savedToChest = false;

  /// cache dell’URL immagine definitiva (dopo upload/risoluzione)
  String? _finalImageUrlCache;

  /// contenuto effettivamente SALVATO (per evitare reset dello stato da update identici)
  String _lastSavedText = '';
  String _lastSavedRawImage = '';
  bool _hasMinTextForDownload = false;

  bool get _hasImageForDownload => _imageUrl.trim().isNotEmpty;

  /// Aggiorna solo se cambia DAVVERO e non è identico all’ultimo SALVATO.
  void _onHonooChanged(String text, String imageUrl) {
    // se identico allo stato attuale → nessun rebuild inutile
    if (text == _text && imageUrl == _imageUrl) return;

    final bool isSameAsLastSaved =
        (text == _lastSavedText && imageUrl == _lastSavedRawImage);

    setState(() {
      _text = text;
      _imageUrl = imageUrl;

      _hasMinTextForDownload = text.trim().isNotEmpty;

      // resetta l’icona solo se il contenuto è DIVERSO da quello salvato
      if (!isSameAsLastSaved) {
        _savedToChest = false;
      }

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
          title: 'Devi accedere',
          message:
              'Per salvare il tuo honoo nello Scrigno devi prima effettuare l\'accesso. Vuoi andare alla pagina di login?',
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
    final newHonoo = Honoo(
      0,
      _text,
      finalImageUrl,
      DateTime.now().toIso8601String(),
      DateTime.now().toIso8601String(),
      user.id,
      HonooType.personal, // scrigno
      null,
      null,
    );

    try {
      await HonooService.publishHonoo(newHonoo);

      if (!mounted) return;
      setState(() {
        _savedToChest = true;
        _finalImageUrlCache = finalImageUrl;
        _lastSavedText = _text;
        _lastSavedRawImage = _imageUrl;
      });

      showHonooToast(context, message: 'salvato nello Scrigno.');
    } catch (e, st) {
      debugPrint('publishHonoo failed: $e\n$st');
      if (!mounted) return;
      showHonooToast(context, message: 'Errore: $e');
    }
  }

  Future<void> _submitToMoon() async {
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

      if (!mounted) return;
      showHonooToast(
        context,
        message: ok ? 'Pubblicato sulla Luna.' : 'Già presente sulla Luna.',
      );
    } catch (e, st) {
      debugPrint('duplicateToMoon failed: $e\n$st');
      if (mounted) {
        showHonooToast(
          context,
          message: 'Errore: $e',
        );
      }
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
          title: 'Devi accedere prima',
          message:
              'Per scaricare questo honoo,\ndevi fare prima il login.\nVuoi andare alla pagina di login?',
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
      _savedToChest = false;
      _finalImageUrlCache = null;
      _lastSavedText = '';
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

    // Padding superiore: solo la parte che serve oltre l’header per non far coprire la luna.
    final double lunaReserve = LunaFissa.reserveTopPadding(context);
    final double extraTop = (lunaReserve - headerH);
    final double contentTopPadding = extraTop > 0 ? extraTop : 0;

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

            // Altezza riservata al footer (3 pulsanti)
            final double footerReserved =
                footerContentH + footerBottomPadding + safeBottom;
            const double controlsH = 44.0;

            // Altezza disponibile per il box honoo
            final double availableH = (viewH -
                    headerH -
                    controlsH -
                    contentTopPadding -
                    footerReserved)
                .clamp(0.0, double.infinity);

            const double gap = 9.0;
            const double builderRatio = 1.5; // totale = imageSize * 1.5 + gap

            final double maxImageByWidth = targetMaxW;
            final double maxImageByHeight =
                ((availableH - gap) / builderRatio).clamp(0.0, double.infinity);

            double imageSize = math.min(maxImageByWidth, maxImageByHeight);
            if (!imageSize.isFinite || imageSize <= 0) {
              imageSize = math.min(targetMaxW, viewW);
            }

            final double builderWidth = imageSize;
            final double builderHeight = imageSize * builderRatio + gap;

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
                    SizedBox(height: contentTopPadding),
                    SizedBox(
                      height: controlsH,
                      child: Center(
                        child: SizedBox(
                          width: builderWidth,
                          height: controlsH,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (_hasMinTextForDownload ||
                                  _hasImageForDownload) ...[
                                WhiteIconButton(
                                  tooltip: 'Scarica honoo',
                                  icon: Icons.download_outlined,
                                  onPressed: _handleDownloadTap,
                                ),
                                const SizedBox(width: 12),
                                WhiteIconButton(
                                  tooltip: 'Elimina honoo',
                                  icon: Icons.delete_outline,
                                  onPressed: _handleDeleteTap,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
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
                            child: ClipRect(
                              child: HonooBuilder(
                                key: _builderKey,
                                onHonooChanged: _onHonooChanged,
                                onFocusChanged: _onBuilderFocusChanged,
                              ),
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
                    bottomPadding: footerBottomPadding,
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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ChestPage()),
                          );
                        },
                      ),
                      if (_savedToChest)
                        ResponsiveFooterAction(
                          asset: "assets/icons/moon.svg",
                          semanticsLabel: 'Luna',
                          size: footerIconSize,
                          splashRadius: 25,
                          tooltip: 'Spedisci sulla Luna',
                          onPressed: _submitToMoon,
                        )
                      else
                        ResponsiveFooterAction(
                          asset: "assets/icons/ok.svg",
                          semanticsLabel: 'OK',
                          size: footerIconSize,
                          splashRadius: 25,
                          tooltip: 'Salva honoo',
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

                const LunaFissa(),
              ],
            );
          },
        ),
      ),
    );
  }
}
