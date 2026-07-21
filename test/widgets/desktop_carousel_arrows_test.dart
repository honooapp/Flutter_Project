import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Widgets/desktop_carousel_arrows.dart';

void main() {
  testWidgets('i controlli del contenuto restano cliccabili', (tester) async {
    int downloads = 0;
    int nextCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DesktopCarouselArrows(
            canPrev: false,
            canNext: true,
            onPrev: () {},
            onNext: () => nextCalls++,
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                key: const ValueKey<String>('download'),
                onPressed: () => downloads++,
                icon: const Icon(Icons.download),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('download')));
    await tester.pump();

    expect(downloads, 1);
    expect(nextCalls, 0);
  });

  testWidgets('le frecce continuano a navigare', (tester) async {
    int prevCalls = 0;
    int nextCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DesktopCarouselArrows(
            canPrev: true,
            canNext: true,
            onPrev: () => prevCalls++,
            onNext: () => nextCalls++,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('desktop_carousel_prev')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('desktop_carousel_next')),
    );
    await tester.pump();

    expect(prevCalls, 1);
    expect(nextCalls, 1);
  });
}
