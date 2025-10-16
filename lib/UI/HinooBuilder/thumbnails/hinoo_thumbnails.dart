import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/UI/hinoo_typography.dart';

class AnteprimaHinoo extends StatelessWidget {
  const AnteprimaHinoo({
    super.key,
    required this.pages,
    required this.currentIndex,
    required this.onTapThumb,
    required this.onAddPage,
    required this.onReorder,
    required this.canvasHeight,
    this.fallbackBgUrl,
    this.fallbackBgTransform,
    this.fallbackBgBytes,
  });

  final List<dynamic> pages;
  final int currentIndex;
  final void Function(int index) onTapThumb;
  final VoidCallback onAddPage;
  final void Function(int oldIndex, int newIndex) onReorder;
  final double canvasHeight;
  final String? fallbackBgUrl;
  final List<dynamic>? fallbackBgTransform; // 16 elementi double
  final Uint8List? fallbackBgBytes;

  @override
  Widget build(BuildContext context) {
    return _ReorderableThumbs(
      pages: pages,
      currentIndex: currentIndex,
      onTapThumb: onTapThumb,
      onReorder: onReorder,
      onAddPage: onAddPage,
      canvasHeight: canvasHeight,
      fallbackBgUrl: fallbackBgUrl,
      fallbackBgTransform: fallbackBgTransform,
      fallbackBgBytes: fallbackBgBytes,
    );
  }
}

class _ReorderableThumbs extends StatelessWidget {
  const _ReorderableThumbs({
    required this.pages,
    required this.currentIndex,
    required this.onTapThumb,
    required this.onReorder,
    required this.onAddPage,
    required this.canvasHeight,
    this.fallbackBgUrl,
    this.fallbackBgTransform,
    this.fallbackBgBytes,
  });

  final List<dynamic> pages;
  final int currentIndex;
  final void Function(int index) onTapThumb;
  final void Function(int oldIndex, int newIndex) onReorder;
  final VoidCallback onAddPage;
  final double canvasHeight;
  final String? fallbackBgUrl;
  final List<dynamic>? fallbackBgTransform;
  final Uint8List? fallbackBgBytes;

  @override
  Widget build(BuildContext context) {
    // Calcola limite massimo e centratura dinamica
    const double aspectRatio = 9 / 16;
    const double thumbHeight = 128;
    const double tileHorizontalPad =
        6; // padding orizzontale per ogni tile (a sinistra e destra)
    const double thumbWidth = thumbHeight * aspectRatio;
    const double tileTotalWidth = thumbWidth + (tileHorizontalPad * 2);

    final int pageCount = pages.length;
    final int visiblePages =
        pageCount > 9 ? 9 : pageCount; // massimo 9 pagine visibili
    final bool showAdd =
        pageCount < 9; // alla nona pagina scompare il pulsante "+"
    final int visibleCount = visiblePages + (showAdd ? 1 : 0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double contentW = tileTotalWidth * visibleCount;
        final double maxW =
            constraints.maxWidth.isFinite ? constraints.maxWidth : contentW;
        final double margin = contentW < maxW ? (maxW - contentW) / 2 : 0;

        return ReorderableListView.builder(
          scrollDirection: Axis.horizontal,
          physics:
              contentW <= maxW ? const NeverScrollableScrollPhysics() : null,
          padding: EdgeInsets.symmetric(horizontal: margin),
          buildDefaultDragHandles: false,
          onReorder: (oldIndex, newIndex) {
            // Se è visibile il "+", impedisci interazioni con esso
            if (showAdd) {
              final int addIndex =
                  visiblePages; // ultimo indice visibile occupato dal tile +
              if (oldIndex == addIndex || newIndex == addIndex) return;
            }
            if (newIndex > oldIndex) newIndex -= 1;
            onReorder(oldIndex, newIndex);
          },
          itemCount: visibleCount,
          itemBuilder: (context, i) {
            final int addIndex =
                visiblePages; // posizione del tile + se presente
            if (showAdd && i == addIndex) {
              // Tile "+" – non riordinabile
              return Padding(
                key: const ValueKey('thumb_add'),
                padding: const EdgeInsets.symmetric(horizontal: tileHorizontalPad),
                child: _AddThumb(onAddPage: onAddPage),
              );
            }

            final page = pages[i];
            return ReorderableDragStartListener(
              key: ValueKey('thumb_$i'),
              index: i,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: tileHorizontalPad),
                child: GestureDetector(
                  onTap: () => onTapThumb(i),
                  child: _ThumbTile(
                    index: i,
                    selected: i == currentIndex,
                    page: page,
                    canvasHeight: canvasHeight,
                    fallbackBgUrl: fallbackBgUrl,
                    fallbackBgTransform: fallbackBgTransform,
                    fallbackBgBytes: fallbackBgBytes,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ThumbTile extends StatelessWidget {
  const _ThumbTile({
    required this.index,
    required this.selected,
    required this.page,
    required this.canvasHeight,
    this.fallbackBgUrl,
    this.fallbackBgTransform,
    this.fallbackBgBytes,
  });

  final int index;
  final bool selected;
  final dynamic page;
  final double canvasHeight;
  final String? fallbackBgUrl;
  final List<dynamic>? fallbackBgTransform;
  final Uint8List? fallbackBgBytes;

  @override
  Widget build(BuildContext context) {
    const double ar = 9 / 16;
    const double thumbH = 128;
    const double thumbW = thumbH * ar;
    const double designHeight = 1920;
    const double designWidth = 1080;

    String? bgUrl = (page is Map) ? page['bgUrl'] as String? : null;
    bgUrl ??= fallbackBgUrl;
    final String text =
        (page is Map && page['text'] is String) ? page['text'] as String : '';
    final int? textColorInt = (page is Map) ? page['textColor'] as int? : null;
    final Color textColor =
        textColorInt != null ? Color(textColorInt) : Colors.white;
    List<dynamic>? transformList =
        (page is Map) ? page['bgTransform'] as List<dynamic>? : null;
    transformList ??= fallbackBgTransform;
    final Matrix4? transform =
        (transformList != null && transformList.length == 16)
            ? Matrix4.fromList(
                transformList.map((e) => (e as num).toDouble()).toList())
            : null;

    final double simulatedWidth = HinooTypography.canvasWidthFromHeight(
        canvasHeight.isFinite && canvasHeight > 0 ? canvasHeight : designHeight);
    final double scaleFactor =
        designWidth / simulatedWidth.clamp(1, designWidth);
    final Matrix4? effectiveTransform;
    if (transform != null) {
      effectiveTransform = transform.clone()
        ..setTranslationRaw(
          transform.storage[12] * scaleFactor,
          transform.storage[13] * scaleFactor,
          transform.storage[14],
        );
    } else {
      effectiveTransform = null;
    }

    final ImageProvider bgProvider;
    if (bgUrl != null && bgUrl.isNotEmpty) {
      bgProvider = NetworkImage(bgUrl);
    } else if (fallbackBgBytes != null && fallbackBgBytes!.isNotEmpty) {
      bgProvider = MemoryImage(fallbackBgBytes!);
    } else {
      bgProvider =
          const AssetImage('assets/images/hinoo_default_1080x1920.png');
    }

    Widget buildBackground() {
      final image = Image(image: bgProvider, fit: BoxFit.cover);
      if (effectiveTransform == null) return image;
      return Transform(
        transform: effectiveTransform,
        alignment: Alignment.center,
        child: image,
      );
    }

    Widget buildPagePreview() {
      const double horizontalPadding = HinooTypography.horizontalPadding;
      final double verticalPadding = HinooTypography.verticalPadding(designWidth);
      final TextStyle textStyle = HinooTypography.displayTextStyle(
        color: textColor,
      );

      return SizedBox(
        width: designWidth,
        height: designHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double maxTextWidth =
                math.max(1, constraints.maxWidth - horizontalPadding * 2);
            final int lineCount =
                _countTextLines(text, maxTextWidth, textStyle);
            final Alignment alignment =
                lineCount > 1 ? Alignment.topCenter : Alignment.center;

            return Stack(
              fit: StackFit.expand,
              children: [
                ClipRect(child: buildBackground()),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: Align(
                    alignment: alignment,
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      softWrap: true,
                      style: textStyle,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return Container(
      width: thumbW,
      height: thumbH,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: selected ? Colors.white : Colors.white24,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: buildPagePreview(),
          ),
          // Numero in alto a destra
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${index + 1}',
                style: GoogleFonts.libreFranklin(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // Contenuto della pagina già renderizzato dal builder in miniatura
        ],
      ),
    );
  }
}

int _countTextLines(String text, double maxWidth, TextStyle style) {
  if (text.isEmpty) return 0;
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
    maxLines: null,
  )..layout(minWidth: 0, maxWidth: maxWidth);

  final int autoLines = painter.computeLineMetrics().length;
  final int manualLines = text.split('\n').length;
  return math.max(autoLines, manualLines);
}

class _AddThumb extends StatelessWidget {
  const _AddThumb({required this.onAddPage});
  final VoidCallback onAddPage;

  @override
  Widget build(BuildContext context) {
    const double ar = 9 / 16;
    const double thumbH = 128;
    const double thumbW = thumbH * ar;
    return InkWell(
      onTap: onAddPage,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: thumbW,
        height: thumbH,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: const Center(
          child: Icon(Icons.add, color: Colors.white70, size: 28),
        ),
      ),
    );
  }
}
