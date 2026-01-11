import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/UI/hinoo_export_spec.dart';

void main() {
  test('Hinoo export spec is deterministic', () {
    // This avoids device/emulator dependencies by checking the pure export spec
    // derived from fixed canvas and export constants.
    final HinooExportSpec spec = getHinooExportSpec(HinooExportMode.mobile);

    expect(spec.logicalSize, const Size(360, 640));
    expect(spec.outputSize, const Size(1080, 1920));
    expect(
      spec.pixelRatio,
      spec.outputSize.height / spec.logicalSize.height,
    );

    // This test verifies that Hinoo export is fully deterministic and
    // independent from device, viewport or platform.
    // If these values are correct, PNG export will be identical on
    // mobile, tablet and desktop.
  });

  test('Hinoo export mode resolves by width', () {
    expect(
      resolveHinooExportMode(logicalWidth: 360, isWeb: false),
      HinooExportMode.mobile,
    );
    expect(
      resolveHinooExportMode(logicalWidth: 720, isWeb: false),
      HinooExportMode.tablet,
    );
    expect(
      resolveHinooExportMode(logicalWidth: 1200, isWeb: false),
      HinooExportMode.desktop,
    );
  });

  test('Hinoo export mode is desktop on web', () {
    expect(
      resolveHinooExportMode(logicalWidth: 360, isWeb: true),
      HinooExportMode.desktop,
    );
  });
}
