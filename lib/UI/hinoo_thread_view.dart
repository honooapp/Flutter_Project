import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:flutter/material.dart';
import 'package:honoo/Entities/hinoo.dart';
import 'package:honoo/UI/hinoo_viewer.dart';
import 'package:honoo/Services/supabase_provider.dart';
import 'package:honoo/Utility/honoo_colors.dart';

class HinooThreadView extends StatelessWidget {
  const HinooThreadView({
    super.key,
    required this.root,
    required this.replies,
    required this.maxHeight,
    required this.maxWidth,
    this.rootAuthorId,
  });

  final HinooDraft root;
  final List<HinooThreadEntry> replies;
  final double maxHeight;
  final double maxWidth;
  final String? rootAuthorId;

  @override
  Widget build(BuildContext context) {
    final List<HinooThreadEntry> items = [
      HinooThreadEntry(draft: root, authorId: rootAuthorId, isReply: false),
      ...replies,
    ];
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
      child: cs.CarouselSlider.builder(
        key: ValueKey(items.length),
        carouselController: cs.CarouselController(),
        itemCount: items.length,
        options: cs.CarouselOptions(
          scrollDirection: Axis.vertical,
          height: maxHeight,
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
            maxHeight: maxHeight,
            maxWidth: maxWidth,
          );
          if (!entry.isReply) return viewer;
          final String? uid = SupabaseProvider.client.auth.currentUser?.id;
          final bool isOwnReply = uid != null && entry.authorId == uid;
          final Color borderColor =
              isOwnReply ? HonooColor.wave2 : HonooColor.secondary;
          return Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: 2),
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
      ),
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
