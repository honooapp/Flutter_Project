// lib/UI/HonooThreadView.dart
import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Widgets/loading_spinner.dart';

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
        Widget child;
        if (state.isLoading) {
          child = const Center(
            key: ValueKey('thread_loading'),
            child: LoadingSpinner(),
          );
        } else if (state.error != null) {
          child = Center(
            key: const ValueKey('thread_error'),
            child: Text(
              'Errore nel caricamento',
              style: GoogleFonts.libreFranklin(
                color: HonooColor.onBackground,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          );
        } else {
          final thread = state.thread;

          if (thread.length <= 1) {
            child = Center(
              key: ValueKey(
                  'thread_single_${widget.root.dbId ?? widget.root.id ?? widget.root.created_at}'),
              child: HonooCard(honoo: widget.root),
            );
          } else {
            child = Padding(
              key: ValueKey(
                  'thread_list_${thread.length}_${thread.first.id ?? ''}'),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: cs.CarouselSlider.builder(
                carouselController: _vController,
                itemCount: thread.length,
                options: cs.CarouselOptions(
                  scrollDirection: Axis.vertical,
                  viewportFraction: 1.0,
                  enableInfiniteScroll: false,
                  padEnds: true,
                  enlargeCenterPage: false,
                  scrollPhysics: const BouncingScrollPhysics(),
                ),
                itemBuilder: (context, index, realIdx) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: HonooCard(honoo: thread[index]),
                  );
                },
              ),
            );
          }
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: child,
        );
      },
    );
  }
}
