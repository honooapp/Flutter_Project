import 'package:flutter/foundation.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Services/supabase_provider.dart';

import '../Entities/honoo.dart';
import '../Services/honoo_image_uploader.dart';
import '../UI/honoo_builder.dart';
import '../Utility/utility.dart';
import 'package:sizer/sizer.dart';
import 'package:honoo/Services/honoo_service.dart';

import '../Widgets/luna_fissa.dart';
import 'email_login_page.dart';
import 'chest_page.dart';
import 'new_hinoo_page.dart';
import '../Widgets/white_icon_button.dart';
import '../Widgets/honoo_dialogs.dart';
import '../UI/HonooBuilder/dialogs/name_honoo_dialog.dart';

class NewHonooPage extends StatefulWidget {
  const NewHonooPage({super.key});

  @override
  State<NewHonooPage> createState() => _NewHonooPageState();
}

class _NewHonooPageState extends State<NewHonooPage> {
  final GlobalKey<HonooBuilderState> _builderKey =
      GlobalKey<HonooBuilderState>();

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

    if (user == null) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EmailLoginPage(
            pendingHonooText: _text,
            pendingImageUrl: _imageUrl,
          ),
        ),
      );
      return;
    }

    // usa cache se presente, altrimenti risolvi adesso
    final String? finalImageUrl =
        _finalImageUrlCache ?? await _resolveFinalImageUrl(_imageUrl);

    if (finalImageUrl == null || finalImageUrl.isEmpty) {
      if (mounted) {
        showHonooToast(
          context,
          message: 'Devi caricare un’immagine (URL pubblico).',
        );
      }
      return;
    }

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
        _savedToChest = true; // passa a “luna”
        _finalImageUrlCache = finalImageUrl;

        // memorizza il contenuto SALVATO per ignorare update identici
        _lastSavedText = _text;
        _lastSavedRawImage = _imageUrl;
      });

      showHonooToast(
        context,
        message: 'Salvato nello scrigno.',
      );
    } catch (e, st) {
      debugPrint('publishHonoo failed: $e\n$st');
      if (mounted) {
        showHonooToast(
          context,
          message: 'Errore: $e',
        );
      }
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

  // Larghezza massima fluida del contenuto (breakpoints morbidi)
  double _contentMaxWidth(double w) {
    if (w < 480) return w * 0.94;
    if (w < 768) return w * 0.92;
    if (w < 1024) return w * 0.84;
    if (w < 1440) return w * 0.70;
    return w * 0.58;
  }

  @override
  Widget build(BuildContext context) {
    // Header compatto per ridurre il gap sopra l’honoo
    const double headerH = 52;

    // Padding superiore: solo la parte che serve oltre l’header per non far coprire la luna.
    final double lunaReserve = LunaFissa.reserveTopPadding(context);
    final double extraTop = (lunaReserve - headerH);
    final double contentTopPadding = extraTop > 0 ? extraTop : 0;

    return Scaffold(
      backgroundColor: HonooColor.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            final double viewW = viewport.maxWidth;
            final double viewH = viewport.maxHeight;

            final double targetMaxW = _contentMaxWidth(viewW);

            // Altezza riservata al footer (3 pulsanti)
            const double footerH = 100.0;
            const double controlsH = 44.0;

            // Altezza disponibile per il box honoo
            final double availableH =
                (viewH - headerH - controlsH - contentTopPadding - footerH)
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
                        child: Text(
                          Utility().appName,
                          style: GoogleFonts.libreFranklin(
                            color: HonooColor.secondary,
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                          ),
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
                              if (_hasMinTextForDownload) ...[
                                WhiteIconButton(
                                  tooltip: 'Scarica honoo',
                                  icon: Icons.download_outlined,
                                  onPressed: _handleDownloadTap,
                                ),
                                const SizedBox(width: 12),
                              ],
                              WhiteIconButton(
                                tooltip: 'Elimina honoo',
                                icon: Icons.delete_outline,
                                onPressed: _handleDeleteTap,
                              ),
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
                  child: Padding(
                    // piccolo margine per non “attaccare” i bottoni al bordo fisico
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
                        SizedBox(width: 5.w),

                        // CHEST
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
                                  builder: (context) => const ChestPage()),
                            );
                          },
                        ),
                        SizedBox(width: 5.w),

                        // OK → LUNA (switch basato su _savedToChest)
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
                                tooltip: 'Salva honoo',
                                onPressed: _submitHonoo,
                              ),
                        SizedBox(width: 5.w),

                        // NUOVA ICONA PIUMA
                        IconButton(
                          icon: SvgPicture.asset(
                            "assets/icons/piuma.svg",
                            semanticsLabel: 'Piuma',
                          ),
                          iconSize: 60,
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
                ), // ===== LUNA FISSA (non copre contenuti, responsive) =====
                const LunaFissa(),
              ],
            );
          },
        ),
      ),
    );
  }
}
