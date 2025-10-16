import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../Entities/hinoo.dart';
import 'hinoo_typography.dart';
import '../Utility/honoo_colors.dart';
import '../Utility/responsive_layout.dart';

class HinooViewer extends StatefulWidget {
  final HinooDraft draft;
  final double maxHeight;
  final double maxWidth;
  final Color gapColor;
  const HinooViewer({
    super.key,
    required this.draft,
    required this.maxHeight,
    required this.maxWidth,
    this.gapColor = HonooColor.background,
  });

  @override
  State<HinooViewer> createState() => _HinooViewerState();
}

class _HinooViewerState extends State<HinooViewer> {
  late final PageController _vController;
  Timer? _snapTimer;

  @override
  void initState() {
    super.initState();
    _vController = PageController();
  }

  @override
  void dispose() {
    _snapTimer?.cancel();
    _vController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double ar = 9 / 16;
    final Size canvasSize = ResponsiveLayout.fitAspectRatio(
      widget.maxWidth,
      widget.maxHeight,
      ar,
    );
    final double w = canvasSize.width;
    final double h = canvasSize.height;

    return Center(
      child: SizedBox(
        width: w,
        height: h,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Listener(
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent &&
                      widget.draft.pages.length > 1 &&
                      _vController.hasClients &&
                      _vController.position.haveDimensions) {
                    final position = _vController.position;
                    if ((position.maxScrollExtent - position.minScrollExtent)
                            .abs() <
                        0.5) {
                      return;
                    }
                    final double target =
                        (position.pixels + event.scrollDelta.dy).clamp(
                            position.minScrollExtent, position.maxScrollExtent);
                    if ((target - position.pixels).abs() > 0.5) {
                      _vController.jumpTo(target);
                      _scheduleSnap();
                    }
                  }
                },
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.stylus,
                      PointerDeviceKind.trackpad,
                    },
                  ),
                  child: PageView.builder(
                    scrollDirection: Axis.vertical,
                    controller: _vController,
                    physics: const PageScrollPhysics(),
                    allowImplicitScrolling: true,
                    itemCount: widget.draft.pages.length,
                    itemBuilder: (context, index) {
                      return HinooSlideView(
                        slide: widget.draft.pages[index],
                        width: w,
                        height: h,
                        gap: 0,
                        gapColor: widget.gapColor,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scheduleSnap() {
    if (widget.draft.pages.length <= 1) return;
    _snapTimer?.cancel();
    _snapTimer = Timer(const Duration(milliseconds: 140), _snapToPage);
  }

  void _snapToPage() {
    _snapTimer?.cancel();
    if (widget.draft.pages.length <= 1) return;
    if (!_vController.hasClients || !_vController.position.haveDimensions) {
      return;
    }
    final double page =
        _vController.page ?? _vController.initialPage.toDouble();
    final int target = page.round().clamp(0, widget.draft.pages.length - 1);
    _vController.animateToPage(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }
}

class HinooSlideView extends StatelessWidget {
  final HinooSlide slide;
  final double width;
  final double height;
  final double gap;
  final Color gapColor;
  const HinooSlideView({
    super.key,
    required this.slide,
    required this.width,
    required this.height,
    required this.gap,
    required this.gapColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = slide.isTextWhite ? Colors.white : Colors.black;
    final ImageProvider bg =
        (slide.backgroundImage != null && slide.backgroundImage!.isNotEmpty)
            ? NetworkImage(slide.backgroundImage!)
            : const AssetImage('assets/images/hinoo_default_1080x1920.png')
                as ImageProvider;

    const double designWidth = 1080;
    const double designHeight = 1920;
    final double scaleX = width / designWidth;
    final double scaleY = height / designHeight;

    Matrix4 buildTransform() {
      if (slide.bgTransform != null && slide.bgTransform!.length == 16) {
        final List<double> m = List<double>.from(slide.bgTransform!);
        m[12] *= scaleX;
        m[13] *= scaleY;
        return Matrix4.fromList(m);
      }

      final double tx = slide.bgOffsetX * scaleX;
      final double ty = slide.bgOffsetY * scaleY;
      return Matrix4.identity()
        ..translate(tx, ty)
        ..scale(slide.bgScale);
    }

    final Matrix4 transform = buildTransform();

    const double horizontalPadding = HinooTypography.horizontalPadding;
    final double verticalPadding = HinooTypography.verticalPadding(width);
    final TextStyle effectiveStyle = HinooTypography.displayTextStyle(
      color: textColor,
    );
    final double halfGap = gap / 2;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: Transform(
              transform: transform,
              alignment: Alignment.center,
              child: Image(image: bg, fit: BoxFit.cover),
            ),
          ),
          Positioned.fill(
            top: gap / 2,
            bottom: gap / 2,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Center(
                child: Text(
                  slide.text,
                  textAlign: TextAlign.center,
                  style: effectiveStyle,
                  softWrap: true,
                ),
              ),
            ),
          ),
          if (halfGap > 0.05)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: halfGap,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: gapColor),
                ),
              ),
            ),
          if (halfGap > 0.05)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: halfGap,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: gapColor),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
