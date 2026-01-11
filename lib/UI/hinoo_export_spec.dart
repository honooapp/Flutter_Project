import 'dart:ui';

import 'package:honoo/UI/hinoo_typography.dart';

enum HinooExportMode {
  mobile,
  tablet,
  desktop,
}

HinooExportMode resolveHinooExportMode({
  required double logicalWidth,
  required bool isWeb,
}) {
  if (isWeb) {
    return HinooExportMode.desktop;
  }

  if (logicalWidth >= 900) {
    return HinooExportMode.desktop;
  }

  if (logicalWidth >= 600) {
    return HinooExportMode.tablet;
  }

  return HinooExportMode.mobile;
}

class HinooExportSpec {
  const HinooExportSpec({
    required this.logicalSize,
    required this.pixelRatio,
    required this.outputSize,
    required this.mode,
  });

  final Size logicalSize;
  final double pixelRatio;
  final Size outputSize;
  final HinooExportMode mode;
}

HinooExportSpec getHinooExportSpec(HinooExportMode mode) {
  const Size logicalSize = Size(
    HinooTypography.baselineCanvasWidth,
    HinooTypography.baselineCanvasHeight,
  );

  // NOTE:
  // Mobile export (1080x1920) is the canonical Hinoo format.
  // Tablet/Desktop exports only adjust visual scale to better match
  // smartphone perception. Layout and typography are unchanged.
  final double pixelRatio;
  switch (mode) {
    case HinooExportMode.mobile:
      pixelRatio =
          HinooTypography.exportHeight / HinooTypography.baselineCanvasHeight;
      break;
    case HinooExportMode.tablet:
      pixelRatio = 3.4;
      break;
    case HinooExportMode.desktop:
      pixelRatio = 3.8;
      break;
  }

  final Size outputSize = Size(
    logicalSize.width * pixelRatio,
    logicalSize.height * pixelRatio,
  );

  return HinooExportSpec(
    logicalSize: logicalSize,
    pixelRatio: pixelRatio,
    outputSize: outputSize,
    mode: mode,
  );
}
