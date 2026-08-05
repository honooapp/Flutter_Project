import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Utility/responsive_layout.dart';

void main() {
  const cases = <({double width, double height})>[
    (width: 320, height: 420),
    (width: 844, height: 260),
    (width: 1024, height: 360),
    (width: 1440, height: 420),
  ];

  for (final viewport in cases) {
    test('Honoo resta nei vincoli a ${viewport.width}x${viewport.height}', () {
      final metrics = ResponsiveLayout.honooBuilderMetrics(
        availableHeight: viewport.height,
        maxWidth: viewport.width,
        mode: ResponsiveLayout.modeForWidth(viewport.width),
      );

      expect(metrics.width, lessThanOrEqualTo(viewport.width));
      expect(metrics.height, lessThanOrEqualTo(viewport.height));
      expect(metrics.width, greaterThanOrEqualTo(0));
      expect(metrics.height, greaterThanOrEqualTo(0));
    });
  }
}
