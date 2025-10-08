import 'dart:ui';

class ResponsiveLayout {
  const ResponsiveLayout._();

  static double contentMaxWidth(double width) {
    if (width < 480) return width * 0.94;
    if (width < 768) return width * 0.92;
    if (width < 1024) return width * 0.84;
    if (width < 1440) return width * 0.70;
    return width * 0.58;
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
}
