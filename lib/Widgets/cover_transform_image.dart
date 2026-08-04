import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A cover-cropped image that can be moved and zoomed without exposing the
/// area behind it.
class CoverTransformImage extends StatefulWidget {
  const CoverTransformImage({
    super.key,
    required this.image,
    required this.transformationController,
    this.interactive = true,
    this.minScale = 1,
    this.maxScale = 5,
  }) : transform = null;

  final ImageProvider image;
  const CoverTransformImage.transformed({
    super.key,
    required this.image,
    required this.transform,
    this.minScale = 1,
    this.maxScale = 5,
  }) : transformationController = null,
       interactive = false;

  final TransformationController? transformationController;
  final Matrix4? transform;
  final bool interactive;
  final double minScale;
  final double maxScale;

  @override
  State<CoverTransformImage> createState() => _CoverTransformImageState();
}

class _CoverTransformImageState extends State<CoverTransformImage> {
  ImageStream? _stream;
  ImageStreamListener? _streamListener;
  ui.Image? _resolvedImage;

  double _gestureStartScale = 1;
  Offset _gestureStartTranslation = Offset.zero;
  Offset _gestureStartFocalPoint = Offset.zero;
  TransformationController? _ownedController;

  TransformationController get _controller =>
      widget.transformationController ?? _ownedController!;

  @override
  void initState() {
    super.initState();
    if (widget.transformationController == null) {
      _ownedController = TransformationController(widget.transform);
    }
    _controller.addListener(_handleTransformChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
  }

  @override
  void didUpdateWidget(CoverTransformImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transformationController != widget.transformationController) {
      final TransformationController oldController =
          oldWidget.transformationController ?? _ownedController!;
      oldController.removeListener(_handleTransformChange);
      _ownedController?.dispose();
      _ownedController = widget.transformationController == null
          ? TransformationController(widget.transform)
          : null;
      _controller.addListener(_handleTransformChange);
    }
    if (oldWidget.image != widget.image) _resolveImage();
    if (widget.transformationController == null &&
        oldWidget.transform != widget.transform &&
        widget.transform != null) {
      _controller.value = widget.transform!;
    }
  }

  @override
  void dispose() {
    _removeImageListener();
    _controller.removeListener(_handleTransformChange);
    _ownedController?.dispose();
    super.dispose();
  }

  void _handleTransformChange() {
    if (mounted) setState(() {});
  }

  void _removeImageListener() {
    if (_stream != null && _streamListener != null) {
      _stream!.removeListener(_streamListener!);
    }
    _stream = null;
    _streamListener = null;
  }

  void _resolveImage() {
    _removeImageListener();
    final ImageStream stream = widget.image.resolve(
      createLocalImageConfiguration(context),
    );
    final ImageStreamListener listener = ImageStreamListener((
      ImageInfo info,
      bool synchronousCall,
    ) {
      if (mounted) setState(() => _resolvedImage = info.image);
    });
    _stream = stream;
    _streamListener = listener;
    stream.addListener(listener);
  }

  double _matrixScale(Matrix4 matrix) {
    final double sx = matrix.storage[0].abs();
    final double sy = matrix.storage[5].abs();
    final double scale = sx > 0 && sy > 0 ? (sx + sy) / 2 : 1;
    return scale.clamp(widget.minScale, widget.maxScale).toDouble();
  }

  Matrix4 _clampedMatrix({
    required double scale,
    required Offset translation,
    required Size viewport,
    required Size coverSize,
  }) {
    final double clampedScale = scale
        .clamp(widget.minScale, widget.maxScale)
        .toDouble();
    final double maxX = ((coverSize.width * clampedScale - viewport.width) / 2)
        .clamp(0, double.infinity);
    final double maxY =
        ((coverSize.height * clampedScale - viewport.height) / 2).clamp(
          0,
          double.infinity,
        );
    final Offset clampedTranslation = Offset(
      translation.dx.clamp(-maxX, maxX).toDouble(),
      translation.dy.clamp(-maxY, maxY).toDouble(),
    );

    return Matrix4.identity()
      ..setEntry(0, 0, clampedScale)
      ..setEntry(1, 1, clampedScale)
      ..setTranslationRaw(clampedTranslation.dx, clampedTranslation.dy, 0);
  }

  bool _matrixNearlyEquals(Matrix4 a, Matrix4 b) {
    for (var i = 0; i < 16; i++) {
      if ((a.storage[i] - b.storage[i]).abs() > 0.001) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final ui.Image? image = _resolvedImage;
        if (image == null ||
            !constraints.hasBoundedWidth ||
            !constraints.hasBoundedHeight) {
          return Image(image: widget.image, fit: BoxFit.cover);
        }

        final Size viewport = Size(constraints.maxWidth, constraints.maxHeight);
        final double coverFactor = math.max(
          viewport.width / image.width,
          viewport.height / image.height,
        );
        final Size coverSize = Size(
          image.width * coverFactor,
          image.height * coverFactor,
        );
        final Matrix4 requested = _controller.value;
        final Matrix4 effective = _clampedMatrix(
          scale: _matrixScale(requested),
          translation: Offset(requested.storage[12], requested.storage[13]),
          viewport: viewport,
          coverSize: coverSize,
        );

        if (!_matrixNearlyEquals(requested, effective)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _controller.value = effective;
          });
        }

        return ClipRect(
          child: GestureDetector(
            key: const Key('cover-image-gesture-area'),
            behavior: HitTestBehavior.opaque,
            onScaleStart: widget.interactive
                ? (ScaleStartDetails details) {
                    final Matrix4 current = _controller.value;
                    _gestureStartScale = _matrixScale(current);
                    _gestureStartTranslation = Offset(
                      current.storage[12],
                      current.storage[13],
                    );
                    _gestureStartFocalPoint = details.localFocalPoint;
                  }
                : null,
            onScaleUpdate: widget.interactive
                ? (ScaleUpdateDetails details) {
                    _controller.value = _clampedMatrix(
                      scale: _gestureStartScale * details.scale,
                      translation:
                          _gestureStartTranslation +
                          details.localFocalPoint -
                          _gestureStartFocalPoint,
                      viewport: viewport,
                      coverSize: coverSize,
                    );
                  }
                : null,
            child: OverflowBox(
              alignment: Alignment.center,
              minWidth: 0,
              minHeight: 0,
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              child: Transform(
                key: const Key('cover-image-transform'),
                transform: effective,
                alignment: Alignment.center,
                child: SizedBox(
                  key: const Key('cover-image-fitted-size'),
                  width: coverSize.width,
                  height: coverSize.height,
                  child: RawImage(image: image, fit: BoxFit.fill),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
