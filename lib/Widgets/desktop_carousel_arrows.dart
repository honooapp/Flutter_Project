import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Desktop-only overlay that adds left/right click areas and arrow hints
/// without affecting layout (stacked on top of the carousel).
class DesktopCarouselArrows extends StatelessWidget {
  const DesktopCarouselArrows({
    super.key,
    required this.child,
    required this.canPrev,
    required this.canNext,
    required this.onPrev,
    required this.onNext,
    this.arrowColor = Colors.white,
    this.arrowSize = 48,
    this.horizontalInset = 16,
  });

  final Widget child;
  final bool canPrev;
  final bool canNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final Color arrowColor;
  final double arrowSize;
  final double horizontalInset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (canPrev)
          Positioned(
            left: horizontalInset,
            top: 0,
            bottom: 0,
            child: Center(
              child: Tooltip(
                message: 'Indietro',
                child: GestureDetector(
                  key: const ValueKey<String>('desktop_carousel_prev'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onPrev,
                  child: SizedBox.square(
                    dimension: arrowSize + 16,
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/arrow_left.svg',
                        width: arrowSize,
                        height: arrowSize,
                        colorFilter:
                            ColorFilter.mode(arrowColor, BlendMode.srcIn),
                        semanticsLabel: 'Indietro',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (canNext)
          Positioned(
            right: horizontalInset,
            top: 0,
            bottom: 0,
            child: Center(
              child: Tooltip(
                message: 'Avanti',
                child: GestureDetector(
                  key: const ValueKey<String>('desktop_carousel_next'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onNext,
                  child: SizedBox.square(
                    dimension: arrowSize + 16,
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/arrow_right.svg',
                        width: arrowSize,
                        height: arrowSize,
                        colorFilter:
                            ColorFilter.mode(arrowColor, BlendMode.srcIn),
                        semanticsLabel: 'Avanti',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
