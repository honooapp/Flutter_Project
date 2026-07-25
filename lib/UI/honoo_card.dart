import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Entities/honoo.dart';
import 'package:honoo/Services/supabase_provider.dart';
import '../Utility/honoo_colors.dart';
import '../Widgets/smooth_image.dart';
import '../Widgets/text_box_download_button.dart';

class HonooCard extends StatelessWidget {
  final Honoo honoo;
  final VoidCallback? onDownloadTap;

  const HonooCard({super.key, required this.honoo, this.onDownloadTap});

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
        cardBg = HonooColor.background;
        break;
    }

    final bool isReply = honoo.type == HonooType.answer;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : media.size.width;
        final double availH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : (media.size.height - media.padding.vertical).clamp(
                0.0,
                double.infinity,
              );

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
            ? HonooColor.tertiary
            : cardBg;

        final Widget content = Card(
          color: cardBg,
          elevation: 0,
          margin: EdgeInsets.zero,
          // Evita clipping dei bordi/ombre esterne applicate dal contenitore padre
          clipBehavior: Clip.none,
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
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Center(
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
                        if (onDownloadTap != null)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: TextBoxDownloadButton(
                              onPressed: onDownloadTap!,
                              tooltip: 'download',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: imageSize,
                  height: gap,
                  child: ColoredBox(
                    key: const Key('honoo-card-gap'),
                    color: gapColor,
                  ),
                ),
                SizedBox(
                  width: imageSize,
                  height: imageSize,
                  child: Container(
                    decoration: BoxDecoration(
                      color: HonooColor.tertiary,
                      borderRadius: BorderRadius.circular(cornerRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    foregroundDecoration: BoxDecoration(
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(cornerRadius),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: hasImage
                        ? SmoothImage(
                            key: const ValueKey('honoo-saved-image'),
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            placeholderColor: HonooColor.tertiary,
                          )
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

        final String? currentUserId =
            SupabaseProvider.client.auth.currentUser?.id;
        final bool isOwn =
            currentUserId != null && currentUserId == honoo.userId;
        // La cornice rossa segnala soltanto una risposta ricevuta.
        // I propri messaggi mantengono il rendering normale.
        final bool showReplyBorder = isReply && !isOwn;
        final bool showMoonSavedBorder = !isReply && honoo.isFromMoonSaved;
        final Widget wrapped = (showReplyBorder || showMoonSavedBorder)
            ? DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: showReplyBorder
                        ? HonooColor.secondary
                        : Colors.white,
                    width: 6,
                  ),
                ),
                child: content,
              )
            : content;

        return Center(child: wrapped);
      },
    );
  }
}
