import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Widgets/cover_transform_image.dart';

void main() {
  const image = AssetImage('assets/icons/laboratori_teatrali.png');

  testWidgets('si può trascinare al livello di zoom iniziale', (tester) async {
    final controller = TransformationController();

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.runAsync(
      () => precacheImage(image, tester.element(find.byType(SizedBox))),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox.square(
            dimension: 200,
            child: CoverTransformImage(
              image: image,
              transformationController: controller,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Size fittedSize = tester.getSize(
      find.byKey(const Key('cover-image-fitted-size')),
    );
    expect(fittedSize.width, closeTo(200, 0.001));
    expect(fittedSize.height, closeTo(302.4, 0.001));

    await tester.drag(
      find.byKey(const Key('cover-image-gesture-area')),
      const Offset(0, -30),
    );
    await tester.pump();

    expect(controller.value.storage[0], closeTo(1, 0.001));
    expect(controller.value.storage[13], closeTo(-30, 1));
  });

  testWidgets('il trascinamento si ferma prima di mostrare lo sfondo', (
    tester,
  ) async {
    final controller = TransformationController();

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.runAsync(
      () => precacheImage(image, tester.element(find.byType(SizedBox))),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox.square(
            dimension: 200,
            child: CoverTransformImage(
              image: image,
              transformationController: controller,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const Key('cover-image-gesture-area')),
      const Offset(0, -500),
    );
    await tester.pump();

    // L'immagine cover è alta 302,4 su un viewport alto 200: il massimo
    // spostamento sicuro è quindi (302,4 - 200) / 2 = 51,2.
    expect(controller.value.storage[13], closeTo(-51.2, 0.01));
  });
}
