import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Entities/Hinoo.dart';

class HinooViewer extends StatefulWidget {
  final HinooDraft draft;
  final double maxHeight;
  final double maxWidth;
  const HinooViewer({super.key, required this.draft, required this.maxHeight, required this.maxWidth});

  @override
  State<HinooViewer> createState() => _HinooViewerState();
}

class _HinooViewerState extends State<HinooViewer> {
  late final PageController _vController;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _vController = PageController();
  }

  @override
  void dispose() {
    _vController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double ar = 9 / 16;
    const double sideDotsW = 20; // larghezza colonna pallini
    const double gap = 8;         // spazio tra card e pallini

    double w = widget.maxWidth;
    double h = w / ar;
    if (h > widget.maxHeight) {
      h = widget.maxHeight;
      w = h * ar;
    }

    return Center(
      child: SizedBox(
        width: w,
        height: h,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (_) {}, // priorità al gesto verticale
                child: PageView.builder(
                  scrollDirection: Axis.vertical,
                  controller: _vController,
                  physics: const PageScrollPhysics(),
                  allowImplicitScrolling: true,
                  itemCount: widget.draft.pages.length,
                  onPageChanged: (i) => setState(() => _current = i),
                  itemBuilder: (context, i) => _HinooSlideView(
                    slide: widget.draft.pages[i],
                    width: w,
                    height: h,
                    baseCanvasHeight: widget.draft.baseCanvasHeight,
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
                child: _HinooPageDots(
                  count: widget.draft.pages.length,
                  currentIndex: _current,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HinooSlideView extends StatelessWidget {
  final HinooSlide slide;
  final double width;
  final double height;
  final double? baseCanvasHeight;
  const _HinooSlideView({
    required this.slide,
    required this.width,
    required this.height,
    required this.baseCanvasHeight,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = slide.isTextWhite ? Colors.white : Colors.black;
    final ImageProvider bg = (slide.backgroundImage != null && slide.backgroundImage!.isNotEmpty)
        ? NetworkImage(slide.backgroundImage!)
        : const AssetImage('assets/images/hinoo_default_1080x1920.png') as ImageProvider;

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

    final double referenceCanvasHeight = (baseCanvasHeight != null && baseCanvasHeight! > 0)
        ? baseCanvasHeight!
        : height;
    final double fontScale = height / referenceCanvasHeight;
    final double fontSize = (20 * fontScale).clamp(10.0, 60.0).toDouble();
    final double padding = (16 * fontScale).clamp(8.0, 40.0).toDouble();

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
          Padding(
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
        ],
      ),
    );
  }
}

// Indicatore verticale a pallini per le pagine Hinoo
class _HinooPageDots extends StatelessWidget {
  final int count;
  final int currentIndex;
  const _HinooPageDots({required this.count, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final double h = box.maxHeight.isFinite ? box.maxHeight : 200;
        final double dot = (h / (count * 3)).clamp(4.0, 10.0);
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
                    color: active ? Colors.white : Colors.white38,
                    border: Border.all(color: Colors.white70, width: active ? 1.2 : 0.8),
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
