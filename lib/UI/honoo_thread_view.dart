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
  const HonooThreadView({super.key, required this.root});

  final Honoo root;

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
              child: HonooCard(honoo: widget.root),
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
                  final bool isReply = honoo.replyTo != null &&
                      honoo.replyTo!.isNotEmpty;
                  final String timestamp = _formatTimestamp(honoo.createdAt);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Stack(
                      children: [
                        HonooCard(honoo: honoo),
                        if (isReply)
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 8,
                            child: _ReplyTimestamp(label: timestamp),
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
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final offset = Tween<Offset>(
              begin: const Offset(0, 0.12),
              end: Offset.zero,
            ).animate(animation);
            return SlideTransition(position: offset, child: child);
          },
          child: child,
        );
      },
    );
  }

  String _formatTimestamp(String raw) {
    final DateTime? parsed = DateTime.tryParse(raw);
    if (parsed == null) return '';
    final DateTime local = parsed.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return 'Nuova risposta · ${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

class _ReplyTimestamp extends StatelessWidget {
  const _ReplyTimestamp({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: HonooColor.background.withOpacity(0.65),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: GoogleFonts.libreFranklin(
          color: HonooColor.onBackground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
