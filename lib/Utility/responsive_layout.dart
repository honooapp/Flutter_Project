import 'dart:math' as math;
import 'dart:ui';

import 'package:honoo/UI/honoo_builder.dart';

enum ResponsiveLayoutMode {
  mobile,
  tablet,
  desktop,
  wideDesktop,
  largeDesktop,
}

class ResponsiveLayout {
  const ResponsiveLayout._();

  static ResponsiveLayoutMode modeForWidth(double width) {
    if (width < 480) return ResponsiveLayoutMode.mobile;
    if (width < 768) return ResponsiveLayoutMode.tablet;
    if (width < 1024) return ResponsiveLayoutMode.desktop;
    if (width < 1440) return ResponsiveLayoutMode.wideDesktop;
    return ResponsiveLayoutMode.largeDesktop;
  }

  static double contentMaxWidth(double width) {
    return contentMaxWidthForMode(modeForWidth(width), width);
  }

  static double contentMaxWidthForMode(
    ResponsiveLayoutMode mode,
    double width,
  ) {
    switch (mode) {
      case ResponsiveLayoutMode.mobile:
        return width * 0.94;
      case ResponsiveLayoutMode.tablet:
        return width * 0.92;
      case ResponsiveLayoutMode.desktop:
        return width * 0.84;
      case ResponsiveLayoutMode.wideDesktop:
        return width * 0.70;
      case ResponsiveLayoutMode.largeDesktop:
        return width * 0.58;
    }
  }

  static Size fitAspectRatio(
    double maxWidth,
    double maxHeight,
    double aspectRatio,
  ) {
    double width = maxWidth;
    double height = width / aspectRatio;

    if (height > maxHeight) {
      height = maxHeight;
      width = height * aspectRatio;
    }

    return Size(width, height);
  }

  static double footerIconSizeForMode(ResponsiveLayoutMode mode) {
    switch (mode) {
      case ResponsiveLayoutMode.mobile:
        return 39;
      case ResponsiveLayoutMode.tablet:
        return 52;
      case ResponsiveLayoutMode.desktop:
        return 44;
      case ResponsiveLayoutMode.wideDesktop:
      case ResponsiveLayoutMode.largeDesktop:
        return 40;
    }
  }

  static double footerGapForMode(ResponsiveLayoutMode mode) {
    switch (mode) {
      case ResponsiveLayoutMode.mobile:
        return 44;
      case ResponsiveLayoutMode.tablet:
        return 40;
      case ResponsiveLayoutMode.desktop:
      case ResponsiveLayoutMode.wideDesktop:
      case ResponsiveLayoutMode.largeDesktop:
        return 32;
    }
  }

  static double footerBottomPaddingForMode(ResponsiveLayoutMode mode) {
    switch (mode) {
      case ResponsiveLayoutMode.mobile:
        return 10;
      case ResponsiveLayoutMode.tablet:
        return 12;
      case ResponsiveLayoutMode.desktop:
      case ResponsiveLayoutMode.wideDesktop:
      case ResponsiveLayoutMode.largeDesktop:
        return 10;
    }
  }

  static HonooBuilderMetrics honooBuilderMetrics({
    required double availableHeight,
    required double maxWidth,
    required ResponsiveLayoutMode mode,
  }) {
    const double builderRatio = 1.5;
    const double gap = HonooBuilder.baselineGap;
    final double maxImageByWidth = maxWidth;
    final double maxImageByHeight =
        ((availableHeight - gap) / builderRatio).clamp(0.0, double.infinity);

    double imageSize = math.min(maxImageByWidth, maxImageByHeight);
    if (mode != ResponsiveLayoutMode.mobile) {
      imageSize = math.max(imageSize, HonooBuilder.baselineImageSize);
    }

    if (!imageSize.isFinite || imageSize <= 0) {
      imageSize = maxWidth;
      if (mode != ResponsiveLayoutMode.mobile) {
        imageSize = math.max(imageSize, HonooBuilder.baselineImageSize);
      }
    }

    final double builderWidth = imageSize;
    final double builderHeight = imageSize * builderRatio + gap;

    return HonooBuilderMetrics(
      imageSize: imageSize,
      width: builderWidth,
      height: builderHeight,
    );
  }
}

class HonooBuilderMetrics {
  final double imageSize;
  final double width;
  final double height;

  const HonooBuilderMetrics({
    required this.imageSize,
    required this.width,
    required this.height,
  });
}
