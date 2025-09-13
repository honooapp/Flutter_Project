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

    // riserva spazio per i pallini a destra
    double availableForCard = (widget.maxWidth - sideDotsW - gap);
    if (availableForCard < 0) availableForCard = widget.maxWidth;

    double w = availableForCard;
    double h = w / ar;
    if (h > widget.maxHeight) {
      h = widget.maxHeight;
      w = h * ar;
    }

    return Center(
      child: SizedBox(
        width: w + gap + sideDotsW,
        height: h,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: w,
              height: h,
              child: ClipRRect(
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
                    itemBuilder: (context, i) => _HinooSlideView(slide: widget.draft.pages[i]),
                  ),
                ),
              ),
            ),
            SizedBox(width: gap),
            SizedBox(
              width: sideDotsW,
              height: h,
              child: _HinooPageDots(
                count: widget.draft.pages.length,
                currentIndex: _current,
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
  const _HinooSlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    final Color textColor = slide.isTextWhite ? Colors.white : Colors.black;
    final ImageProvider bg = (slide.backgroundImage != null && slide.backgroundImage!.isNotEmpty)
        ? NetworkImage(slide.backgroundImage!)
        : const AssetImage('assets/images/hinoo_default_1080x1920.png') as ImageProvider;

    // Applica trasformazioni basilari (scale/offset) per coerenza
    final Matrix4 transform = Matrix4.identity()
      ..translate(slide.bgOffsetX, slide.bgOffsetY)
      ..scale(slide.bgScale);

    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          child: Transform(
            transform: transform,
            alignment: Alignment.center,
            child: Image(image: bg),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              slide.text,
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(
                color: textColor,
                fontSize: 16,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
          ),
        ),
      ],
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

