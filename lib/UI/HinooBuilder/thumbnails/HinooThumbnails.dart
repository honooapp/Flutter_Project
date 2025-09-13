import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:google_fonts/google_fonts.dart';

class AnteprimaHinoo extends StatelessWidget {
  const AnteprimaHinoo({
    super.key,
    required this.pages,
    required this.currentIndex,
    required this.onTapThumb,
    required this.onAddPage,
    required this.onReorder,
    this.fallbackBgUrl,
    this.fallbackBgTransform,
    this.fallbackBgBytes,
  });

  final List<dynamic> pages;
  final int currentIndex;
  final void Function(int index) onTapThumb;
  final VoidCallback onAddPage;
  final void Function(int oldIndex, int newIndex) onReorder;
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
    this.fallbackBgUrl,
    this.fallbackBgTransform,
    this.fallbackBgBytes,
  });

  final List<dynamic> pages;
  final int currentIndex;
  final void Function(int index) onTapThumb;
  final void Function(int oldIndex, int newIndex) onReorder;
  final VoidCallback onAddPage;
  final String? fallbackBgUrl;
  final List<dynamic>? fallbackBgTransform;
  final Uint8List? fallbackBgBytes;

  @override
  Widget build(BuildContext context) {
    // Calcola limite massimo e centratura dinamica
    const double _ar = 9 / 16;
    const double _thumbH = 128;
    const double _tileHPad = 6; // padding orizzontale per ogni tile (a sinistra e destra)
    const double _thumbW = _thumbH * _ar;
    const double _tileTotalW = _thumbW + (_tileHPad * 2);

    final int pageCount = pages.length;
    final int visiblePages = pageCount > 9 ? 9 : pageCount; // massimo 9 pagine visibili
    final bool showAdd = pageCount < 9; // alla nona pagina scompare il pulsante "+"
    final int visibleCount = visiblePages + (showAdd ? 1 : 0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double contentW = _tileTotalW * visibleCount;
        final double maxW = constraints.maxWidth.isFinite ? constraints.maxWidth : contentW;
        final double margin = contentW < maxW ? (maxW - contentW) / 2 : 0;

        return ReorderableListView.builder(
          scrollDirection: Axis.horizontal,
          physics: contentW <= maxW ? const NeverScrollableScrollPhysics() : null,
          padding: EdgeInsets.symmetric(horizontal: margin),
          buildDefaultDragHandles: false,
          onReorder: (oldIndex, newIndex) {
            // Se è visibile il "+", impedisci interazioni con esso
            if (showAdd) {
              final int addIndex = visiblePages; // ultimo indice visibile occupato dal tile +
              if (oldIndex == addIndex || newIndex == addIndex) return;
            }
            if (newIndex > oldIndex) newIndex -= 1;
            onReorder(oldIndex, newIndex);
          },
          itemCount: visibleCount,
          itemBuilder: (context, i) {
            final int addIndex = visiblePages; // posizione del tile + se presente
            if (showAdd && i == addIndex) {
              // Tile "+" – non riordinabile
              return Padding(
                key: const ValueKey('thumb_add'),
                padding: const EdgeInsets.symmetric(horizontal: _tileHPad),
                child: _AddThumb(onAddPage: onAddPage),
              );
            }

            final page = pages[i];
            return ReorderableDragStartListener(
              key: ValueKey('thumb_$i'),
              index: i,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: _tileHPad),
                child: GestureDetector(
                  onTap: () => onTapThumb(i),
                  child: _ThumbTile(
                    index: i,
                    selected: i == currentIndex,
                    page: page,
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
    this.fallbackBgUrl,
    this.fallbackBgTransform,
    this.fallbackBgBytes,
  });

  final int index;
  final bool selected;
  final dynamic page;
  final String? fallbackBgUrl;
  final List<dynamic>? fallbackBgTransform;
  final Uint8List? fallbackBgBytes;

  @override
  Widget build(BuildContext context) {
    const double ar = 9 / 16;
    const double thumbH = 128;
    const double thumbW = thumbH * ar;

    String? bgUrl = (page is Map) ? page['bgUrl'] as String? : null;
    bgUrl ??= fallbackBgUrl;
    final String text = (page is Map && page['text'] is String) ? page['text'] as String : '';
    final int? textColorInt = (page is Map) ? page['textColor'] as int? : null;
    final Color textColor = textColorInt != null ? Color(textColorInt) : Colors.white;
    List<dynamic>? transformList = (page is Map) ? page['bgTransform'] as List<dynamic>? : null;
    transformList ??= fallbackBgTransform;
    final Matrix4? transform = (transformList != null && transformList.length == 16)
        ? Matrix4.fromList(transformList.map((e) => (e as num).toDouble()).toList())
        : null;

    Widget bg;
    if (bgUrl != null && bgUrl.isNotEmpty) {
      bg = Image.network(bgUrl, fit: BoxFit.cover);
    } else if (fallbackBgBytes != null) {
      bg = Image.memory(fallbackBgBytes!, fit: BoxFit.cover);
    } else {
      bg = const Image(
        image: AssetImage('assets/images/hinoo_default_1080x1920.png'),
        fit: BoxFit.cover,
      );
    }

    if (transform != null) {
      bg = Transform(
        transform: transform,
        alignment: Alignment.center,
        child: bg,
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
            child: SizedBox(
              width: thumbW,
              height: thumbH,
              child: bg,
            ),
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
          // Testo centrato
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.arvo(
                  color: textColor,
                  fontSize: 12,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
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
