// lib/UI/honoo_thread_view.dart
import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Widgets/loading_spinner.dart';

import '../Controller/honoo_thread_loader.dart';
import '../Entities/honoo.dart';
import '../UI/honoo_card.dart';
import '../Utility/honoo_colors.dart';
 

/// Una pagina del carosello orizzontale della ChestPage.
/// Se il root honoo ha risposte, mostra un CarouselSlider verticale senza peek,
/// con gutter laterale fisso, così i box non toccano mai i bordi.
class HonooThreadView extends StatefulWidget {
  const HonooThreadView({
    super.key,
    required this.root,
    this.onDownloadTap,
  });

  final Honoo root;
  final VoidCallback? onDownloadTap;

  @override
  State<HonooThreadView> createState() => _HonooThreadViewState();
}

class _HonooThreadViewState extends State<HonooThreadView>
    with SingleTickerProviderStateMixin {
  late final HonooThreadLoader _loader;
  final _vController = cs.CarouselController();
  late final AnimationController _introController;
  late final Animation<double> _introCurve;
  late final AnimationController _bounceController;
  late final Animation<double> _bounceCurve;
  // Micro-hint per suggerire contenuto successivo (12px max)
  late final AnimationController _hintController;
  late final Animation<double> _hintCurve;
  bool _hinted = false;
  int _lastIndex = 0;
  // niente hint verticale: primo messaggio sempre ancorato in alto

  String _honooIdentity(Honoo honoo) {
    final String? dbId = honoo.dbId;
    if (dbId != null && dbId.isNotEmpty) {
      return dbId;
    }
    final int localId = honoo.id;
    if (localId != 0) {
      return localId.toString();
    }
    return honoo.createdAt;
  }

  @override
  void initState() {
    super.initState();
    _loader = HonooThreadLoader()..load(widget.root);
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _introCurve = CurvedAnimation(parent: _introController, curve: Curves.easeOutBack);
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _bounceCurve = CurvedAnimation(parent: _bounceController, curve: Curves.easeOutBack);
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _hintCurve = TweenSequence<double>([
      TweenSequenceItem(
        tween: CurveTween(curve: Curves.easeOut),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: CurveTween(curve: Curves.easeIn),
        weight: 50,
      ),
    ]).animate(_hintController);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _introController.forward();
    });
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
    _introController.dispose();
    _bounceController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Il contenitore (ChestPage) impone già maxWidth/maxHeight
    return ValueListenableBuilder<HonooThreadState>(
      valueListenable: _loader,
      builder: (context, state, _) {
        Widget child;
        final bool hasReplies =
            !state.isLoading && state.error == null && state.thread.length > 1;
        if (hasReplies && !_hinted) {
          _hinted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _hintController.forward(from: 0);
          });
        }
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
              key: ValueKey('thread_single_${_honooIdentity(widget.root)}'),
              child: HonooCard(
                honoo: widget.root,
                onDownloadTap: widget.onDownloadTap,
              ),
            );
          } else {
            final Honoo root = thread.firstWhere(
              (h) => h.replyTo == null || h.replyTo!.isEmpty,
              orElse: () => widget.root,
            );
            final List<Honoo> replies = thread
                .where((h) => h.replyTo != null && h.replyTo!.isNotEmpty)
                .toList();
            // Ordina le risposte dal più vecchio al più recente e mostra la radice per prima
            replies.sort((a, b) {
              final DateTime? aTime = DateTime.tryParse(a.createdAt);
              final DateTime? bTime = DateTime.tryParse(b.createdAt);
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return aTime.compareTo(bTime);
            });
            final List<Honoo> ordered = [root, ...replies];
            child = LayoutBuilder(
              builder: (ctx, c) {
                final double h = c.maxHeight.isFinite ? c.maxHeight : MediaQuery.of(ctx).size.height;
                final double w = c.maxWidth.isFinite ? c.maxWidth : MediaQuery.of(ctx).size.width;
                final double dy = (1.0 - _introCurve.value) * 12.0 - (_bounceCurve.value * 6.0);
                // Rimbalzo: sali fino a metà schermo (negativo) e ritorna alla posizione iniziale
                final double hint = -_hintCurve.value * (h * 0.5);
                final double scale = 1.0 - (1.0 - _introCurve.value) * 0.01 - (_bounceCurve.value * 0.005);
                return Transform.translate(
                  offset: Offset(0, -dy + hint),
                  child: Transform.scale(
                    scale: scale.clamp(0.97, 1.0),
                    child: SizedBox(
                      width: w,
                      height: h,
                      child: KeyedSubtree(
                        key: ValueKey(
                            'thread_list_${thread.length}_${_honooIdentity(thread.first)}'),
                        child: cs.CarouselSlider.builder(
                          carouselController: _vController,
                          itemCount: ordered.length,
                          options: cs.CarouselOptions(
                            height: h,
                            scrollDirection: Axis.vertical,
                            viewportFraction: 1.0,
                            enableInfiniteScroll: false,
                            padEnds: false,
                            enlargeCenterPage: false,
                            scrollPhysics: const BouncingScrollPhysics(),
                            onPageChanged: (index, reason) {
                              if (index > _lastIndex) {
                                _bounceController.forward(from: 0);
                              }
                              _lastIndex = index;
                            },
                          ),
                          itemBuilder: (context, index, realIdx) {
                            final honoo = ordered[index];
                            return HonooCard(
                              honoo: honoo,
                              onDownloadTap: widget.onDownloadTap,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            if (!hasReplies) {
              final offset = Tween<Offset>(
                begin: const Offset(0, 0.12),
                end: Offset.zero,
              ).animate(animation);
              return SlideTransition(position: offset, child: child);
            }
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.elasticOut,
            );
            final offset = Tween<Offset>(
              begin: const Offset(0, 0.28),
              end: Offset.zero,
            ).animate(curved);
            final scale = Tween<double>(begin: 0.97, end: 1.0).animate(curved);
            return SlideTransition(
              position: offset,
              child: ScaleTransition(
                scale: scale,
                child: FadeTransition(opacity: animation, child: child),
              ),
            );
          },
          child: child,
        );
      },
    );
  }

}

// No cover wrapper: we show HonooCard at its natural metrics like normal honoo
