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

class _HonooThreadViewState extends State<HonooThreadView> {
  late final HonooThreadLoader _loader;
  final _vController = cs.CarouselController();

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
        final bool hasReplies =
            !state.isLoading && state.error == null && state.thread.length > 1;
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
            replies.sort((a, b) {
              final DateTime? aTime = DateTime.tryParse(a.createdAt);
              final DateTime? bTime = DateTime.tryParse(b.createdAt);
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime);
            });
            final List<Honoo> ordered = [...replies, root];
            child = Padding(
              key: ValueKey(
                  'thread_list_${thread.length}_${_honooIdentity(thread.first)}'),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: cs.CarouselSlider.builder(
                carouselController: _vController,
                itemCount: ordered.length,
                options: cs.CarouselOptions(
                  scrollDirection: Axis.vertical,
                  viewportFraction: 1.0,
                  enableInfiniteScroll: false,
                  padEnds: true,
                  enlargeCenterPage: false,
                  scrollPhysics: const BouncingScrollPhysics(),
                ),
                itemBuilder: (context, index, realIdx) {
                  final honoo = ordered[index];
                  final bool isReply = false; // i bordi top-level sono gestiti a livello carosello
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Stack(
                          children: [
                            HonooCard(
                              honoo: honoo,
                              onDownloadTap: widget.onDownloadTap,
                            ),
                            if (isReply)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: HonooColor.secondary,
                                          width: 2),
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  );
                },
              ),
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
