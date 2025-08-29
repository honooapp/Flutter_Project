// lib/Pages/NewHinooPage.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:honoo/Utility/HonooColors.dart';
import 'package:honoo/Utility/Utility.dart';
import 'package:honoo/Widgets/LunaFissa.dart';

import '../Entities/Hinoo.dart';
import 'ChestPage.dart';
import 'EmailLoginPage.dart';

// Builder + Entities
import 'package:honoo/UI/HinooBuilder.dart';

// ✅ Controller (nuovo)
import 'package:honoo/Controller/HinooController.dart';

class NewHinooPage extends StatefulWidget {
  const NewHinooPage({super.key});

  @override
  State<NewHinooPage> createState() => _NewHinooPageState();
}

class _NewHinooPageState extends State<NewHinooPage> {
  /// Chiave per interrogare il builder (export del draft completo)
  final GlobalKey<HinooBuilderState> _builderKey = GlobalKey<HinooBuilderState>();

  /// Controller centralizzato per validazione, upload immagini e publish/duplicate
  final _controller = HinooController();

  /// Stato "salvato nello scrigno" → il bottone OK diventa "luna"
  bool _savedToChest = false;

  /// Cache dell’ultimo fingerprint salvato (per non resettare inutilmente l’icona)
  String _lastSavedFingerprint = '';

  /// Callback dal builder per aggiornare lo stato e resettare l’icona se necessario
  void _onHinooChanged(HinooDraft draft) {
    final fp = _controller.fingerprint(draft);
    if (fp == _lastSavedFingerprint) return; // identico a quanto salvato
    if (_savedToChest) {
      setState(() => _savedToChest = false); // è cambiato → torna “OK”
    }
  }

  Future<void> _submitHinoo() async {
    // Preserviamo il comportamento: se non loggato → vai a login
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EmailLoginPage()),
      );
      return;
    }

    final draft = _builderKey.currentState?.exportDraft();
    if (draft == null || draft.pages.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Crea almeno 1 schermata 16:9 con sfondo e testo.')),
        );
      }
      return;
    }

    try {
      // 👉 delega al controller: valida, risolve immagini, salva su “scrigno”
      final fp = await _controller.saveToChest(draft);

      if (!mounted) return;
      setState(() {
        _savedToChest = true;            // switch a “luna”
        _lastSavedFingerprint = fp;      // memorizza fingerprint salvato
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hinoo salvato nello scrigno.')),
      );
    } catch (e, st) {
      debugPrint('publishHinoo failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }

  Future<void> _submitToMoon() async {
    final draft = _builderKey.currentState?.exportDraft();
    if (draft == null || draft.pages.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nessun contenuto da pubblicare sulla Luna.')),
        );
      }
      return;
    }

    try {
      // 👉 delega al controller: valida, risolve immagini, duplica su “Luna”
      final res = await _controller.sendToMoon(draft);

      if (!mounted) return;
      final msg = (res == HinooMoonResult.published)
          ? 'Pubblicato sulla Luna.'
          : 'Già presente sulla Luna.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e, st) {
      debugPrint('duplicateToMoon failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }

  // Larghezza massima fluida del contenuto (come NewHonooPage)
  double _contentMaxWidth(double w) {
    if (w < 480) return w * 0.94;
    if (w < 768) return w * 0.92;
    if (w < 1024) return w * 0.84;
    if (w < 1440) return w * 0.70;
    return w * 0.58;
  }

  @override
  Widget build(BuildContext context) {
    // Header compatto come in NewHonooPage
    const double headerH = 52;

    // Padding superiore per non far coprire la luna (stessa logica)
    final double lunaReserve = LunaFissa.reserveTopPadding(context);
    final double extraTop = (lunaReserve - headerH);
    final double contentTopPadding = extraTop > 0 ? extraTop : 0;

    // Altezza riservata al footer (3 pulsanti)
    const double footerH = 100.0;

    return Scaffold(
      backgroundColor: HonooColor.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            final double viewW = viewport.maxWidth;
            final double viewH = viewport.maxHeight;
            final double targetMaxW = _contentMaxWidth(viewW);

            // Altezza disponibile per il box centrale
            final double availableH =
            (viewH - headerH - contentTopPadding - footerH).clamp(0.0, double.infinity);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // ===== HEADER + EDITOR =====
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
                        // top minimo + spazio per footer
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
                                child: HinooBuilder(
                                  key: _builderKey,
                                  onHinooChanged: _onHinooChanged,
                                  // ✅ inizializza reply mode quando serve
                                  // initialType: HinooType.answer,
                                  // initialReplyTo: 'ID_ORIGINALE',
                                  // initialRecipientTag: '@poetaBlu',

                                  // ✅ opzionale: ricevi PNG export per salvarlo su storage o condividerlo
                                  onPngExported: (bytes) async {
                                    // esempio: mostra solo are-you-sure
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('PNG ricevuto (memoria): pronto a salvare/condividere.')),
                                    );
                                    // Se vuoi: carica su storage (aggiungo metodo ad hoc nel controller nel prossimo step).
                                  },
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
                    // margine per non incollare i bottoni al bordo fisico
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // HOME
                        IconButton(
                          icon: SvgPicture.asset(
                            "assets/icons/home.svg",
                            semanticsLabel: 'Home',
                          ),
                          iconSize: 60,
                          splashRadius: 25,
                          color: HonooColor.onBackground,
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 24),

                        // CHEST
                        IconButton(
                          icon: SvgPicture.asset(
                            "assets/icons/chest.svg",
                            semanticsLabel: 'Chest',
                          ),
                          iconSize: 60,
                          splashRadius: 40,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ChestPage()),
                            );
                          },
                        ),
                        const SizedBox(width: 24),

                        // OK → LUNA (switch basato su _savedToChest)
                        _savedToChest
                            ? IconButton(
                          icon: SvgPicture.asset(
                            "assets/icons/moon.svg",
                            semanticsLabel: 'Luna',
                          ),
                          iconSize: 32,
                          splashRadius: 25,
                          onPressed: _submitToMoon,
                        )
                            : IconButton(
                          icon: SvgPicture.asset(
                            "assets/icons/ok.svg",
                            semanticsLabel: 'OK',
                          ),
                          iconSize: 60,
                          splashRadius: 25,
                          onPressed: _submitHinoo,
                        ),
                      ],
                    ),
                  ),
                ),

                // ===== LUNA FISSA (non copre contenuti, responsive) =====
                const LunaFissa(),
              ],
            );
          },
        ),
      ),
    );
  }
}
