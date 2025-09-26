import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Entities/Hinoo.dart';
import '../Utility/HonooColors.dart';
import '../Utility/Utility.dart';
import 'HinooViewer.dart';

class MoonHinooView extends StatefulWidget {
  const MoonHinooView({
    super.key,
    required this.draft,
    required this.maxHeight,
    required this.maxWidth,
    this.backgroundColor = Colors.white,
  });

  final HinooDraft draft;
  final double maxHeight;
  final double maxWidth;
  final Color backgroundColor;

  @override
  State<MoonHinooView> createState() => _MoonHinooViewState();
}

class _MoonHinooViewState extends State<MoonHinooView> {
  late final PageController _controller;
  int _current = 0;

  static const double _titleHeight = 52;
  static const double _controlsHeight = 44;
  static const double _indicatorHeight = 20;
  static const double _verticalSpacing = 16;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _contentMaxWidth(double w) {
    if (w < 480) return w * 0.94;
    if (w < 768) return w * 0.92;
    if (w < 1024) return w * 0.84;
    if (w < 1440) return w * 0.70;
    return w * 0.58;
  }

  @override
  Widget build(BuildContext context) {
    final double viewWidth = widget.maxWidth;
    final double viewHeight = widget.maxHeight;

    final double targetMaxWidth = _contentMaxWidth(viewWidth);
    final double reservedHeight = _titleHeight + _controlsHeight + _indicatorHeight + (_verticalSpacing * 3);
    final double availableCanvasHeight = (viewHeight - reservedHeight).clamp(0.0, double.infinity);

    const double aspectRatio = 9 / 16;
    double canvasWidth = targetMaxWidth;
    double canvasHeight = canvasWidth / aspectRatio;

    if (canvasHeight > availableCanvasHeight && availableCanvasHeight > 0) {
      canvasHeight = availableCanvasHeight;
      canvasWidth = canvasHeight * aspectRatio;
    }

    final pages = widget.draft.pages;
    final hasPages = pages.isNotEmpty;
    final int pageCount = hasPages ? pages.length : 1;

    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          SizedBox(
            height: _titleHeight,
            child: Center(
              child: Text(
                Utility().appName,
                style: GoogleFonts.libreFranklin(
                  color: HonooColor.secondary,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: _verticalSpacing),
          SizedBox(
            height: _controlsHeight,
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.public, color: HonooColor.secondary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Luna',
                    style: GoogleFonts.libreFranklin(
                      color: HonooColor.secondary,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.draft.recipientTag != null && widget.draft.recipientTag!.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: HonooColor.secondary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#${widget.draft.recipientTag!}',
                        style: GoogleFonts.libreFranklin(
                          color: HonooColor.secondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: _verticalSpacing),
          Expanded(
            child: Center(
              child: SizedBox(
                width: canvasWidth,
                height: canvasHeight,
                child: hasPages
                    ? _buildPageView(pages, canvasWidth, canvasHeight)
                    : _buildEmptyPlaceholder(),
              ),
            ),
          ),
          const SizedBox(height: _verticalSpacing),
          SizedBox(
            height: _indicatorHeight,
            child: hasPages && pageCount > 1
                ? _buildIndicator(pageCount)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildPageView(List<HinooSlide> pages, double width, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: PageView.builder(
        controller: _controller,
        itemCount: pages.length,
        physics: pages.length == 1
            ? const NeverScrollableScrollPhysics()
            : const PageScrollPhysics(),
        onPageChanged: (index) => setState(() => _current = index),
        itemBuilder: (context, index) {
          return HinooSlideView(
            slide: pages[index],
            width: width,
            height: height,
            baseCanvasHeight: widget.draft.baseCanvasHeight,
            gap: 0,
            gapColor: widget.backgroundColor,
          );
        },
      ),
    );
  }

  Widget _buildIndicator(int pageCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final bool isActive = index == _current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 18 : 8,
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? HonooColor.secondary
                : HonooColor.secondary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _buildEmptyPlaceholder() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HonooColor.secondary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          'Nessun contenuto disponibile',
          style: GoogleFonts.libreFranklin(
            color: HonooColor.secondary.withOpacity(0.6),
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
