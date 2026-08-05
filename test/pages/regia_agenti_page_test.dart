import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Pages/placeholder_page.dart';
import 'package:honoo/Pages/regia_agenti_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('la landing mostra il link e la relativa icona SVG', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: PlaceholderPage()));
    await tester.pumpAndSettle();

    final link = find.text('Regia degli Agenti');
    expect(link, findsOneWidget);

    final aiIcon = find.byWidgetPredicate(
      (widget) =>
          widget is SvgPicture &&
          widget.bytesLoader is SvgAssetLoader &&
          (widget.bytesLoader as SvgAssetLoader).assetName ==
              'assets/icons/ai.svg',
    );
    expect(aiIcon, findsOneWidget);

    final visibleTexts = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data)
        .whereType<String>()
        .toList();
    final viaggiIndex = visibleTexts.indexOf("viaggi sull'Isola delle Storie");
    final regiaIndex = visibleTexts.indexOf('Regia degli Agenti');
    final podcastIndex = visibleTexts.indexOf('podcast e dirette');
    expect(regiaIndex, viaggiIndex + 1);
    expect(regiaIndex, lessThan(podcastIndex));

    await tester.ensureVisible(link);
    await tester.tap(link);
    await tester.pumpAndSettle();

    expect(find.byType(RegiaAgentiPage), findsOneWidget);
  });

  testWidgets('la pagina mostra il testo completo nello stile informativo', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegiaAgentiPage()));
    await tester.pumpAndSettle();

    final text = tester.widget<Text>(
      find.byKey(const Key('regia_agenti_text')),
    );
    expect(text.data, RegiaAgentiPage.regiaAgentiText);
    expect(text.textAlign, TextAlign.center);
    expect(text.data, contains('Alessandro Molina'));
    expect(text.data, contains('Behavior Driven Design'));
    expect(text.data, contains('Sì,\nstiamo parlando'));
  });
}
