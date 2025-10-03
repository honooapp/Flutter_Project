import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Entities/Hinoo.dart';
import '../Utility/HonooColors.dart';
import '../Utility/ResponsiveLayout.dart';

class HinooViewer extends StatefulWidget {
  final HinooDraft draft;
  final double maxHeight;
  final double maxWidth;
  final Color gapColor;
  final bool showDotsBorder;
  final HinooIndicatorStyle? indicatorStyle;
  const HinooViewer({
    super.key,
    required this.draft,
    required this.maxHeight,
    required this.maxWidth,
    this.gapColor = HonooColor.background,
    this.showDotsBorder = false,
    this.indicatorStyle,
  });

  @override
  State<HinooViewer> createState() => _HinooViewerState();
}

class _HinooViewerState extends State<HinooViewer> {
  late final PageController _vController;
  int _current = 0;
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
    const double sideDotsW = 20; // larghezza colonna pallini
    const double gap = 8; // spazio tra card e pallini

    final Size canvasSize = ResponsiveLayout.fitAspectRatio(
      widget.maxWidth,
      widget.maxHeight,
      ar,
    );
    final double w = canvasSize.width;
    final double h = canvasSize.height;

    final HinooIndicatorStyle indicatorStyle = widget.indicatorStyle ??
        (widget.showDotsBorder
            ? HinooIndicatorStyle.moon()
            : const HinooIndicatorStyle.chest());

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
                    if ((position.maxScrollExtent -
                            position.minScrollExtent)
                        .abs() <
                        0.5) {
                      return;
                    }
                    final double target = (position.pixels + event.scrollDelta.dy)
                        .clamp(position.minScrollExtent, position.maxScrollExtent);
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
                    onPageChanged: (i) => setState(() => _current = i),
                    itemBuilder: (context, index) {
                      return AnimatedBuilder(
                        animation: _vController,
                        builder: (context, child) {
                          double distance = 0.0;
                          if (_vController.hasClients &&
                              _vController.position.haveDimensions) {
                            final double page =
                                _vController.page ?? _vController.initialPage.toDouble();
                            distance = (page - index).abs();
                          } else {
                            distance = (_current - index).abs().toDouble();
                          }
                          const double maxGap = 18.0;
                          final double gap =
                              (distance.clamp(0.0, 1.0) * maxGap).clamp(0.0, maxGap);
                          return HinooSlideView(
                            slide: widget.draft.pages[index],
                            width: w,
                            height: h,
                            baseCanvasHeight: widget.draft.baseCanvasHeight,
                            gap: gap,
                            gapColor: widget.gapColor,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              right: -(gap + sideDotsW),
              top: 0,
              bottom: 0,
              child: SizedBox(
                width: sideDotsW,
                height: h,
                child: HinooPageDotsColumn(
                  count: widget.draft.pages.length,
                  currentIndex: _current,
                  style: indicatorStyle,
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
    if (!_vController.hasClients ||
        !_vController.position.haveDimensions) return;
    final double page = _vController.page ?? _vController.initialPage.toDouble();
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
  final double? baseCanvasHeight;
  final double gap;
  final Color gapColor;
  const HinooSlideView({super.key,
    required this.slide,
    required this.width,
    required this.height,
    required this.baseCanvasHeight,
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

    final double referenceCanvasHeight =
        (baseCanvasHeight != null && baseCanvasHeight! > 0)
            ? baseCanvasHeight!
            : height;
    final double fontScale = height / referenceCanvasHeight;
    final double fontSize = (20 * fontScale).clamp(10.0, 60.0).toDouble();
    final double padding = (16 * fontScale).clamp(8.0, 40.0).toDouble();
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
              padding: EdgeInsets.all(padding),
              child: Center(
                child: Text(
                  slide.text,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lora(
                    color: textColor,
                    fontSize: fontSize,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
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

// Indicatore verticale a pallini per le pagine Hinoo
class HinooPageDotsColumn extends StatelessWidget {
  final int count;
  final int currentIndex;
  final HinooIndicatorStyle style;

  const HinooPageDotsColumn({
    super.key,
    required this.count,
    required this.currentIndex,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final double h = box.maxHeight.isFinite ? box.maxHeight : 200;
        final double dot = count > 0
            ? (h / (count * 3)).clamp(4.0, 10.0)
            : 0;
        final double gap = dot;
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(count, (i) {
              final bool active = i == currentIndex;
              return Padding(
                padding: EdgeInsets.symmetric(vertical: gap / 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: dot,
                  height: dot,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? style.activeColor : style.inactiveColor,
                    border: Border.all(
                      color: style.borderColor,
                      width: active
                          ? style.activeBorderWidth
                          : style.inactiveBorderWidth,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class HinooIndicatorStyle {
  final Color activeColor;
  final Color inactiveColor;
  final Color borderColor;
  final double activeBorderWidth;
  final double inactiveBorderWidth;

  const HinooIndicatorStyle({
    required this.activeColor,
    required this.inactiveColor,
    required this.borderColor,
    this.activeBorderWidth = 1.4,
    this.inactiveBorderWidth = 0.9,
  });

  const HinooIndicatorStyle.chest()
      : this(
          activeColor: Colors.white,
          inactiveColor: Colors.white38,
          borderColor: Colors.white70,
        );

  factory HinooIndicatorStyle.moon() => HinooIndicatorStyle(
        activeColor: HonooColor.onTertiary,
        inactiveColor: HonooColor.onTertiary.withOpacity(0.32),
        borderColor: HonooColor.onTertiary.withOpacity(0.45),
      );
}
