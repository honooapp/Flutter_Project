import 'package:flutter/material.dart';

/// Paints the full-quality image as soon as its first frame is available.
///
/// No lower-quality preview is used: until then, only [placeholderColor] is
/// visible. Images already held by Flutter's cache are painted immediately.
class SmoothImage extends StatefulWidget {
  const SmoothImage({
    super.key,
    required this.image,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.placeholderColor = Colors.transparent,
    this.fadeDuration = const Duration(milliseconds: 280),
    this.cacheWidth,
    this.cacheHeight,
  });

  final ImageProvider image;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final Color placeholderColor;
  final Duration fadeDuration;
  final int? cacheWidth;
  final int? cacheHeight;

  @override
  State<SmoothImage> createState() => _SmoothImageState();
}

class _SmoothImageState extends State<SmoothImage> {
  int _attempt = 0;

  Future<void> _retry() async {
    await widget.image.evict();
    if (mounted) setState(() => _attempt++);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ratio = MediaQuery.devicePixelRatioOf(context);
        final width = widget.cacheWidth ??
            (constraints.maxWidth.isFinite
                ? (constraints.maxWidth * ratio).round().clamp(1, 4096)
                : null);
        final height = widget.cacheHeight ??
            (constraints.maxHeight.isFinite
                ? (constraints.maxHeight * ratio).round().clamp(1, 4096)
                : null);
        final provider = ResizeImage.resizeIfNeeded(
          width,
          height,
          widget.image,
        );
        return ColoredBox(
          color: widget.placeholderColor,
          child: Image(
            key: ValueKey(_attempt),
            image: provider,
            fit: widget.fit,
            alignment: widget.alignment,
            filterQuality: FilterQuality.medium,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) return child;
              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: widget.fadeDuration,
                curve: Curves.easeOutCubic,
                child: child,
              );
            },
            errorBuilder: (context, error, stackTrace) => Center(
              child: IconButton(
                onPressed: _retry,
                tooltip: 'Riprova a caricare l’immagine',
                icon: const Icon(Icons.refresh, color: Colors.white70),
              ),
            ),
          ),
        );
      },
    );
  }
}
