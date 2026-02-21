import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:flutter/material.dart';
import 'package:honoo/Entities/hinoo.dart';
import 'package:honoo/UI/hinoo_viewer.dart';
import 'package:honoo/Services/supabase_provider.dart';
import 'package:honoo/Utility/honoo_colors.dart';
 

class HinooThreadView extends StatefulWidget {
  const HinooThreadView({
    super.key,
    required this.root,
    required this.replies,
    required this.maxHeight,
    required this.maxWidth,
    this.rootAuthorId,
    this.onDownloadTap,
  });

  final HinooDraft root;
  final List<HinooThreadEntry> replies;
  final double maxHeight;
  final double maxWidth;
  final String? rootAuthorId;
  final VoidCallback? onDownloadTap;

  @override
  State<HinooThreadView> createState() => _HinooThreadViewState();
}

class _HinooThreadViewState extends State<HinooThreadView> {
  final cs.CarouselController _vController = cs.CarouselController();

  @override
  Widget build(BuildContext context) {
    final List<HinooThreadEntry> sortedReplies = [...widget.replies];
    sortedReplies.sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) return 0;
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });
    final List<HinooThreadEntry> items = [
      ...sortedReplies,
      HinooThreadEntry(
          draft: widget.root, authorId: widget.rootAuthorId, isReply: false),
    ];
    final slider = cs.CarouselSlider.builder(
      key: ValueKey(items.length),
      carouselController: _vController,
      itemCount: items.length,
      options: cs.CarouselOptions(
        scrollDirection: Axis.vertical,
        height: widget.maxHeight,
        viewportFraction: 1.0,
        enableInfiniteScroll: false,
        padEnds: true,
        enlargeCenterPage: false,
        scrollPhysics: const BouncingScrollPhysics(),
      ),
      itemBuilder: (context, index, realIdx) {
          final entry = items[index];
          final Widget viewer = HinooViewer(
            draft: entry.draft,
            maxHeight: widget.maxHeight,
            maxWidth: widget.maxWidth,
            onDownloadTap: widget.onDownloadTap,
          );
          if (!entry.isReply) return viewer;
          return Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: HonooColor.secondary, width: 2),
                ),
                child: viewer,
              ),
              if (entry.createdAt != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 8,
                  child: _ReplyTimestamp(
                    label: _formatTimestamp(entry.createdAt!),
                  ),
                ),
            ],
          );
      },
    );

    final bool hasReplies = items.length > 1;
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
        final curved = CurvedAnimation(parent: animation, curve: Curves.elasticOut);
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
      child: slider,
    );
  }

  String _formatTimestamp(DateTime ts) {
    final DateTime local = ts.toLocal();
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
        style: const TextStyle(
          color: HonooColor.onBackground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class HinooThreadEntry {
  const HinooThreadEntry({
    required this.draft,
    required this.authorId,
    required this.isReply,
    this.createdAt,
  });

  final HinooDraft draft;
  final String? authorId;
  final bool isReply;
  final DateTime? createdAt;
}
