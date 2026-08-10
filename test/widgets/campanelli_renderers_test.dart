import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Entities/campanelli_view_data.dart';
import 'package:honoo/UI/hinoo_typography.dart';
import 'package:honoo/Widgets/campanello_card.dart';
import 'package:honoo/Widgets/casa_section.dart';

void main() {
  const casa = CasaData(
    id: 'casa-1',
    backgroundImage: AssetImage('assets/images/casa_palombaro.png'),
    bgScale: 1,
    bgOffsetX: 0,
    bgOffsetY: 0,
  );

  testWidgets('campanello introduttivo conserva il collegamento clicca qui', (
    tester,
  ) async {
    var requested = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CampanelloCard(
            data: CampanelloPageData.intro(
              'Per richiedere il tuo campanello clicca qui',
            ),
            width: 320,
            height: 500,
            onRequestTap: () => requested = true,
          ),
        ),
      ),
    );

    expect(find.text('clicca qui'), findsOneWidget);
    await tester.tap(find.text('clicca qui'));
    expect(requested, isTrue);
  });

  testWidgets('campanello reale conserva sfondo e testo', (tester) async {
    const campanello = CampanelloData(
      id: 'campanello-1',
      campanelloHinooId: null,
      ownerId: 'owner-1',
      backgroundImage: AssetImage('assets/campanello1.png'),
      text: 'Un campanello',
      linkedHouseId: 'casa-1',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CampanelloCard(
            data: CampanelloPageData.campanello(campanello),
            width: 320,
            height: 500,
          ),
        ),
      ),
    );

    expect(find.text('Un campanello'), findsOneWidget);
    final savedTextPosition = tester.widget<Align>(
      find.byKey(const ValueKey('campanello-saved-text-position')),
    );
    expect(savedTextPosition.alignment, Alignment.topCenter);
    final background = find.byWidgetPredicate(
      (widget) => widget is Image && widget.image == campanello.backgroundImage,
    );
    expect(background, findsOneWidget);
    expect(
      tester
              .getRect(
                find.byKey(const ValueKey('campanello-saved-text-position')),
              )
              .top -
          tester.getRect(background).top,
      closeTo(HinooTypography.editorTextTopPadding(320), 0.01),
    );
  });

  testWidgets('casa chiusa conserva messaggio e azione scrigno', (
    tester,
  ) async {
    var opened = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CasaSection(
            casa: casa,
            isUnlocked: false,
            scrignoAsset: 'assets/images/casa_palombaro_con_scrigno.png',
            onScrignoTap: () => opened = true,
            footerIconSize: 40,
            scrignoSize: 80,
            footerBottomSpacing: 10,
            width: 320,
            height: 500,
          ),
        ),
      ),
    );

    expect(find.text('Casa chiusa'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/casa_palombaro_con_scrigno.png',
      ),
      findsOneWidget,
    );
    tester.widget<GestureDetector>(find.byType(GestureDetector)).onTap!();
    expect(opened, isTrue);
  });

  testWidgets('casa aperta mostra lo sfondo senza messaggio di chiusura', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CasaSection(
            casa: casa,
            isUnlocked: true,
            scrignoAsset: 'assets/images/casa_palombaro_con_scrigno.png',
            footerIconSize: 40,
            scrignoSize: 80,
            footerBottomSpacing: 10,
            width: 320,
            height: 500,
          ),
        ),
      ),
    );

    expect(find.text('Casa chiusa'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Image && widget.image == casa.backgroundImage,
      ),
      findsOneWidget,
    );
  });
}
