// lib/UI/HonooThreadView.dart
import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Controller/HonooThreadLoader.dart';
import '../Entities/Honoo.dart';
import '../UI/HonooCard.dart';
import '../Utility/HonooColors.dart';

/// Una pagina del carosello orizzontale della ChestPage.
/// Se il root honoo ha risposte, mostra un CarouselSlider verticale senza peek,
/// con gutter laterale fisso, così i box non toccano mai i bordi.
class HonooThreadView extends StatefulWidget {
  const HonooThreadView({super.key, required this.root});

  final Honoo root;

  @override
  State<HonooThreadView> createState() => _HonooThreadViewState();
}

class _HonooThreadViewState extends State<HonooThreadView> {
  late final HonooThreadLoader _loader;
  final _vController = cs.CarouselController();

  @override
  void initState() {
    super.initState();
    _loader = HonooThreadLoader()..load(widget.root);
  }

  @override
  void didUpdateWidget(covariant HonooThreadView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.root != widget.root) {
      _loader.load(widget.root);
    }
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Il contenitore (ChestPage) impone già maxWidth/maxHeight
    return ValueListenableBuilder<HonooThreadState>(
      valueListenable: _loader,
      builder: (context, state, _) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null) {
          return Center(
            child: Text(
              'Errore nel caricamento',
              style: GoogleFonts.libreFranklin(
                color: HonooColor.onBackground,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          );
        }

        final thread = state.thread;

        // Nessuna risposta: un solo box (l’honoo)
        if (thread.length <= 1) {
          return Center(child: HonooCard(honoo: widget.root));
        }

        // Conversazione: root + replies (ordinati per created_at ASC nel controller)
        return Padding(
          // GUTTER ORIZZONTALE fisso: i box non toccano mai i lati
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: cs.CarouselSlider.builder(
            carouselController: _vController,
            itemCount: thread.length,
            options: cs.CarouselOptions(
              scrollDirection: Axis.vertical,
              viewportFraction: 1.0,                 // nessun peek verticale
              enableInfiniteScroll: false,
              padEnds: true,                         // margine anche primo/ultimo
              enlargeCenterPage: false,              // niente enlarge verticale
              scrollPhysics: const BouncingScrollPhysics(),
            ),
            itemBuilder: (context, index, realIdx) {
              return Padding(
                // piccolo respiro tra messaggi della conversazione
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: HonooCard(honoo: thread[index]),
              );
            },
          ),
        );
      },
    );
  }
}
