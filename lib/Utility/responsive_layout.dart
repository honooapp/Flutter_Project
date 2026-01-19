import 'dart:ui';

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
        return 45;
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
        return 14;
      case ResponsiveLayoutMode.tablet:
        return 12;
      case ResponsiveLayoutMode.desktop:
      case ResponsiveLayoutMode.wideDesktop:
      case ResponsiveLayoutMode.largeDesktop:
        return 10;
    }
  }
}
