import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/IsolaDelleStorie/Pages/full_island_page.dart';
import 'package:sizer/sizer.dart';

void main() {
  for (final size in <Size>[
    const Size(320, 568),
    const Size(390, 844),
    const Size(1024, 768),
  ]) {
    testWidgets(
      'toolbar Isola completa usa gli stessi offset a ${size.width.toInt()} px',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) =>
                const MaterialApp(home: FullIslandPage()),
          ),
        );
        await tester.pump();

        final bottle = find.byKey(const Key('island_footer_bottle'));
        final chest = find.byKey(const Key('island_footer_chest'));
        final info = find.byKey(const Key('island_footer_info'));

        expect(tester.widget<Positioned>(bottle).bottom, 27);
        expect(tester.widget<Positioned>(chest).bottom, -7);
        expect(tester.widget<Positioned>(info).bottom, -5);

        for (final icon in <Finder>[bottle, chest, info]) {
          final rect = tester.getRect(icon);
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(size.width));
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
