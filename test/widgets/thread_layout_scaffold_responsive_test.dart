import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/UI/thread_layout_scaffold.dart';
import 'package:honoo/Utility/responsive_layout.dart';
import 'package:honoo/Widgets/luna_fissa.dart';

void main() {
  const viewportCases = <({Size size, double safeTop, double safeBottom})>[
    (size: Size(320, 568), safeTop: 0, safeBottom: 0),
    (size: Size(390, 844), safeTop: 47, safeBottom: 34),
    (size: Size(768, 1024), safeTop: 24, safeBottom: 20),
    (size: Size(1366, 768), safeTop: 0, safeBottom: 0),
    (size: Size(1440, 900), safeTop: 0, safeBottom: 0),
  ];

  for (final viewport in viewportCases) {
    testWidgets('senza Luna il viewer usa tutta l area tra header e footer a '
        '${viewport.size.width.toInt()}x${viewport.size.height.toInt()}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = viewport.size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final media = MediaQueryData(
        size: viewport.size,
        padding: EdgeInsets.only(
          top: viewport.safeTop,
          bottom: viewport.safeBottom,
        ),
        viewPadding: EdgeInsets.only(
          top: viewport.safeTop,
          bottom: viewport.safeBottom,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: media,
            child: ThreadLayoutScaffold(
              backgroundColor: Colors.black,
              header: const SizedBox(key: Key('header')),
              bodyBuilder: (context, width, height, mode) => const ColoredBox(
                key: Key('full-viewer-area'),
                color: Colors.black,
              ),
              footerBuilder:
                  (context, mode, iconSize, gap, topSpacing, bottomSpacing) =>
                      SizedBox(
                        key: const Key('footer'),
                        height: iconSize + bottomSpacing,
                      ),
            ),
          ),
        ),
      );

      final bodyRect = tester.getRect(
        find.byKey(const Key('full-viewer-area')),
      );
      final footerRect = tester.getRect(find.byKey(const Key('footer')));
      final mode = ResponsiveLayout.modeForWidth(viewport.size.width);
      final footerSpacing =
          ResponsiveLayout.footerBottomPaddingForMode(mode) +
          viewport.safeBottom;
      final footerTopSpacing = footerSpacing / 2;

      expect(bodyRect.top, ThreadLayoutScaffold.headerHeight);
      expect(bodyRect.bottom + footerTopSpacing, footerRect.top);
      expect(bodyRect.left, 0);
      expect(bodyRect.right, viewport.size.width);
    });

    for (final kind in _CardKind.values) {
      testWidgets('${kind.name} centrato e separato da Luna/footer a '
          '${viewport.size.width.toInt()}x${viewport.size.height.toInt()}', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = viewport.size;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        final media = MediaQueryData(
          size: viewport.size,
          padding: EdgeInsets.only(
            top: viewport.safeTop,
            bottom: viewport.safeBottom,
          ),
          viewPadding: EdgeInsets.only(
            top: viewport.safeTop,
            bottom: viewport.safeBottom,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: media,
              child: ThreadLayoutScaffold(
                backgroundColor: Colors.black,
                header: const SizedBox(key: Key('header')),
                bodyTopInsetBuilder: (context, mode) =>
                    (LunaFissa.reserveTopPadding(context) -
                            ThreadLayoutScaffold.headerHeight)
                        .clamp(0.0, double.infinity),
                bodyBuilder: (context, width, height, mode) => ColoredBox(
                  key: const Key('safe-body'),
                  color: Colors.black,
                  child: Center(
                    child: _ResponsiveTestCard(
                      kind: kind,
                      maxWidth: width,
                      maxHeight: height,
                    ),
                  ),
                ),
                footerBuilder:
                    (context, mode, iconSize, gap, topSpacing, bottomSpacing) =>
                        SizedBox(
                          key: const Key('footer'),
                          height: iconSize + bottomSpacing,
                        ),
                overlayBuilder: (context, mode) {
                  final width = MediaQuery.sizeOf(context).width;
                  final iconSize = LunaFissa.iconSizeForWidth(width);
                  final margin = width >= 1200 ? 16.0 : 8.0;
                  return Positioned(
                    key: const Key('moon'),
                    top: viewport.safeTop + margin,
                    right: margin,
                    width: iconSize,
                    height: iconSize,
                    child: const ColoredBox(color: Colors.white),
                  );
                },
              ),
            ),
          ),
        );

        final bodyRect = tester.getRect(find.byKey(const Key('safe-body')));
        final cardRect = tester.getRect(find.byKey(const Key('card')));
        final moonRect = tester.getRect(find.byKey(const Key('moon')));
        final footerRect = tester.getRect(find.byKey(const Key('footer')));

        expect(moonRect.bottom, lessThanOrEqualTo(bodyRect.top));
        expect(bodyRect.bottom, lessThanOrEqualTo(footerRect.top));
        expect(cardRect.center.dx, closeTo(bodyRect.center.dx, 0.01));
        expect(cardRect.center.dy, closeTo(bodyRect.center.dy, 0.01));
        expect(cardRect.left, greaterThanOrEqualTo(bodyRect.left - 0.01));
        expect(cardRect.top, greaterThanOrEqualTo(bodyRect.top - 0.01));
        expect(cardRect.right, lessThanOrEqualTo(bodyRect.right + 0.01));
        expect(cardRect.bottom, lessThanOrEqualTo(bodyRect.bottom + 0.01));

        final expected = _cardSize(kind, bodyRect.width, bodyRect.height);
        expect(cardRect.width, closeTo(expected.width, 0.01));
        expect(cardRect.height, closeTo(expected.height, 0.01));
      });
    }
  }
}

enum _CardKind { honoo, hinoo }

Size _cardSize(_CardKind kind, double maxWidth, double maxHeight) {
  if (kind == _CardKind.hinoo) {
    return ResponsiveLayout.fitAspectRatio(maxWidth, maxHeight, 9 / 16);
  }
  const gap = 9.0;
  final imageSize = math.min(
    maxWidth,
    ((maxHeight - gap) / 1.5).clamp(0.0, double.infinity),
  );
  return Size(imageSize, imageSize * 1.5 + gap);
}

class _ResponsiveTestCard extends StatelessWidget {
  const _ResponsiveTestCard({
    required this.kind,
    required this.maxWidth,
    required this.maxHeight,
  });

  final _CardKind kind;
  final double maxWidth;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final size = _cardSize(kind, maxWidth, maxHeight);
    return SizedBox(
      key: const Key('card'),
      width: size.width,
      height: size.height,
    );
  }
}
