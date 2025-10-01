import 'package:flutter/foundation.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:honoo/Utility/HonooColors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Entities/Honoo.dart';
import '../Services/HonooImageUploader.dart';
import '../UI/HonooBuilder.dart';
import '../Utility/Utility.dart';
import 'package:sizer/sizer.dart';
import 'package:honoo/Services/HonooService.dart';

import '../Widgets/LunaFissa.dart';
import 'EmailLoginPage.dart';
import 'ChestPage.dart';
import 'NewHinooPage.dart';

class NewHonooPage extends StatefulWidget {
  const NewHonooPage({super.key});

  @override
  State<NewHonooPage> createState() => _NewHonooPageState();
}

class _NewHonooPageState extends State<NewHonooPage> {
  String _text = '';
  String _imageUrl = '';

  /// stato: dopo salvataggio nello scrigno il bottone diventa “luna”
  bool _savedToChest = false;

  /// cache dell’URL immagine definitiva (dopo upload/risoluzione)
  String? _finalImageUrlCache;

  /// contenuto effettivamente SALVATO (per evitare reset dello stato da update identici)
  String _lastSavedText = '';
  String _lastSavedRawImage = '';

  /// Aggiorna solo se cambia DAVVERO e non è identico all’ultimo SALVATO.
  void _onHonooChanged(String text, String imageUrl) {
    // se identico allo stato attuale → nessun rebuild inutile
    if (text == _text && imageUrl == _imageUrl) return;

    final bool isSameAsLastSaved =
    (text == _lastSavedText && imageUrl == _lastSavedRawImage);

    setState(() {
      _text = text;
      _imageUrl = imageUrl;

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
    final user = Supabase.instance.client.auth.currentUser;

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Devi caricare un’immagine (URL pubblico).')),
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
        _savedToChest = true;               // passa a “luna”
        _finalImageUrlCache = finalImageUrl;

        // memorizza il contenuto SALVATO per ignorare update identici
        _lastSavedText = _text;
        _lastSavedRawImage = _imageUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salvato nello scrigno.')),
      );
    } catch (e, st) {
      debugPrint('publishHonoo failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
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
        Supabase.instance.client.auth.currentUser?.id ?? '',
        HonooType.personal,
        null,
        null,
      );

      final ok = await HonooService.duplicateToMoon(honooForMoon);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Pubblicato sulla Luna.' : 'Già presente sulla Luna.')),
      );
    } catch (e, st) {
      debugPrint('duplicateToMoon failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }

  Future<String?> _resolveFinalImageUrl(String raw) async {
    final s = raw.trim();
    if (s.isEmpty) return null;

    if (s.startsWith('http://') || s.startsWith('https://')) return s;

    if (kIsWeb && s.startsWith('blob:')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Immagine locale (blob) non caricabile dal browser.')),
        );
      }
      return null;
    }

    final uploaded = await HonooImageUploader.uploadImageFromPath(s);
    return uploaded;
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

            // Altezza disponibile per il box honoo
            final double availableH =
            (viewH - headerH - contentTopPadding - footerH)
                .clamp(0.0, double.infinity);

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
                    Expanded(
                      child: Padding(
                        // top minimo (solo se la luna uscirebbe dall’header) + spazio per footer in basso
                        padding: EdgeInsets.fromLTRB(0, contentTopPadding, 0, footerH),
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 90),
                            curve: Curves.easeOutCubic,
                            constraints: BoxConstraints(maxWidth: targetMaxW),
                            child: SizedBox(
                              height: availableH,
                              width: double.infinity,
                              child: ClipRect(
                                child: HonooBuilder(
                                  onHonooChanged: _onHonooChanged,
                                ),
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
                              MaterialPageRoute(builder: (context) => ChestPage()),
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
                          tooltip: 'Scrivi',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const NewHinooPage()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),       // ===== LUNA FISSA (non copre contenuti, responsive) =====
                const LunaFissa(),
              ],

            );
          },
        ),
      ),
    );
  }
}
