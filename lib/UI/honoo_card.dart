import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Entities/honoo.dart';
import '../Utility/honoo_colors.dart';
import '../Services/supabase_provider.dart';

class HonooCard extends StatelessWidget {
  final Honoo honoo;

  const HonooCard({super.key, required this.honoo});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    Color cardBg;
    switch (honoo.type) {
      case HonooType.moon:
        cardBg = HonooColor.tertiary;
        break;
      case HonooType.answer:
        cardBg = HonooColor.secondary;
        break;
      case HonooType.personal:
      default:
        cardBg = HonooColor.background;
        break;
    }

    final String? uid = SupabaseProvider.client.auth.currentUser?.id;
    final bool isOwnReply = uid != null && honoo.userId == uid;
    final Color? replyBorder = honoo.type == HonooType.answer
        ? (isOwnReply ? HonooColor.wave2 : HonooColor.secondary)
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : media.size.width;
        final double availH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : (media.size.height - media.padding.vertical)
                .clamp(0.0, double.infinity);

        if (availW <= 0 || availH <= 0) {
          return const SizedBox.shrink();
        }

        // Parametri layout
        const double gap = 9.0; // spazio tra box testo e immagine
        const double eps = 0.5; // cuscinetto anti-rounding
        final double maxByH = (availH - gap - eps) / 1.5;
        final double imageSize = math.min(availW, maxByH);
        final double textHeight = imageSize / 2;
        final double totalHeight = textHeight + gap + imageSize;

        final String imageUrl = honoo.image.toString();
        final bool hasImage = imageUrl.isNotEmpty;

        const double cornerRadius = 5;

        final Color gapColor = honoo.type == HonooType.moon
            ? HonooColor.background
            : cardBg;

        final Widget content = Card(
          color: cardBg,
          elevation: 0,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cornerRadius),
          ),
          child: SizedBox(
            width: imageSize,
            height: totalHeight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: imageSize,
                  height: textHeight,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: HonooColor.tertiary,
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(cornerRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        honoo.text,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.arvo(
                          color: HonooColor.onTertiary,
                          fontSize: 18,
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 5,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ),
                ),

                SizedBox(
                  width: imageSize,
                  height: gap,
                  child: ColoredBox(color: gapColor),
                ),

                SizedBox(
                  width: imageSize,
                  height: imageSize,
                  child: Container(
                    decoration: BoxDecoration(
                      color: HonooColor.tertiary,
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(cornerRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      image: hasImage
                          ? DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: hasImage
                        ? const SizedBox.shrink()
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Carica qui la tua immagine',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.libreFranklin(
                                  color: HonooColor.onSecondary,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 22),
                              const Icon(
                                Icons.photo,
                                size: 48,
                                color: HonooColor.primary,
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        );

        final Widget wrapped = replyBorder == null
            ? content
            : Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(cornerRadius + 6),
                  border: Border.all(color: replyBorder, width: 2),
                ),
                child: content,
              );

        return Center(child: wrapped);
      },
    );
  }
}
