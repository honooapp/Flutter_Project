import 'package:flutter/gestures.dart';
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
    final svg = tester.widget<SvgPicture>(aiIcon);
    expect(svg.height, 45);
    final transform = tester.widget<Transform>(
      find.byKey(const Key('regia_agenti_icon_transform')),
    );
    expect(transform.transform.getTranslation().y, -2);
    expect(
      svg.colorFilter,
      const ColorFilter.mode(Color.fromRGBO(183, 183, 206, 1), BlendMode.srcIn),
    );
    expect(
      tester
          .getSize(find.byKey(const Key('regia_agenti_icon_top_spacing')))
          .height,
      closeTo(23.4, 0.001),
    );
    expect(
      tester
          .getSize(find.byKey(const Key('regia_agenti_icon_bottom_spacing')))
          .height,
      30,
    );
    expect(
      tester.getSize(find.byKey(const Key('isola_icon_bottom_spacing'))).height,
      30,
    );

    final visibleTexts = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data)
        .whereType<String>()
        .toList();
    expect(
      visibleTexts,
      containsAll(<String>[
        'Performance',
        'Laboratori teatrali',
        'Esplorazioni lunari',
        'Feste',
        "Viaggi sull'Isola delle Storie",
        'La Banda',
        'Bando honoo\nper Francolise',
        'Regia degli Agenti',
        'Podcast e dirette',
        'Libri',
      ]),
    );
    final viaggiIndex = visibleTexts.indexOf("Viaggi sull'Isola delle Storie");
    final laBandaIndex = visibleTexts.indexOf('La Banda');
    final bandoFrancoliseIndex = visibleTexts.indexOf(
      'Bando honoo\nper Francolise',
    );
    final regiaIndex = visibleTexts.indexOf('Regia degli Agenti');
    final podcastIndex = visibleTexts.indexOf('Podcast e dirette');
    final libriIndex = visibleTexts.indexOf('Libri');
    expect(laBandaIndex, viaggiIndex + 1);
    expect(bandoFrancoliseIndex, laBandaIndex + 1);
    expect(regiaIndex, bandoFrancoliseIndex + 1);
    expect(regiaIndex, lessThan(podcastIndex));
    expect(libriIndex, podcastIndex + 1);

    await tester.ensureVisible(link);
    await tester.tap(link);
    await tester.pumpAndSettle();

    expect(find.byType(RegiaAgentiPage), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await tester.ensureVisible(aiIcon);
    await tester.tap(aiIcon);
    await tester.pumpAndSettle();

    expect(find.byType(RegiaAgentiPage), findsOneWidget);
  });

  testWidgets('la pagina mostra il testo completo nello stile informativo', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegiaAgentiPage()));
    await tester.pumpAndSettle();

    final text = tester.widget<Text>(find.byKey(const Key('section_text')));
    expect(text.textSpan?.toPlainText(), RegiaAgentiPage.regiaAgentiText);
    expect(text.textAlign, TextAlign.center);
    expect(text.textSpan?.toPlainText(), contains('Alessandro Molina'));
    expect(text.textSpan?.toPlainText(), contains('Behavior Driven Design'));
    expect(text.textSpan?.toPlainText(), contains('Sì,\nstiamo parlando'));
    expect(text.textSpan?.toPlainText(), contains('guidando agenti AI'));
    expect(text.textSpan?.toPlainText(), contains('a tessere scenari'));
    expect(text.textSpan?.toPlainText(), isNot(contains('a tessere idee')));
    expect(
      text.textSpan?.toPlainText(),
      endsWith('E dirigere\ngli agenti\nsignifica\nimparare\na tessere\n\n'),
    );

    final rootSpan = text.textSpan! as TextSpan;
    final alessandroSpan = rootSpan.children!.whereType<TextSpan>().singleWhere(
      (span) => span.text == 'Alessandro Molina',
    );
    expect(alessandroSpan.recognizer, isA<TapGestureRecognizer>());
    expect(alessandroSpan.style?.decoration, TextDecoration.underline);
    expect(alessandroSpan.style?.decorationThickness, 3);
  });
}
