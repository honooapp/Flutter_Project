import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:honoo/Utility/build_metadata.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Widgets/chest_info_dialog.dart';

void main() {
  testWidgets('informativa Scrigno è scorrevole e si chiude', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showChestInfoDialog(context),
            child: const Text('Apri'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();

    expect(find.byType(ChestInfoDialog), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.textContaining('Questo è il tuo Scrigno'), findsOneWidget);
    const chestInfoText = chestInfoTextBeforeIcons + chestInfoTextAfterIcons;
    expect(chestInfoText, isNot(contains('.')));
    expect(chestInfoText, isNot(contains('Blu\n')));
    expect(chestInfoText, isNot(contains('Bianchi\n')));
    expect(chestInfoText, isNot(contains('Rossi\n')));
    expect(chestInfoText, contains('Sopra\nla tua risposta'));
    expect(chestInfoText, contains('E, sopra ancora,'));
    expect(chestInfoText, isNot(contains('Sotto\n')));
    expect(chestInfoText, isNot(contains('sotto ancora')));
    for (final asset in const [
      'assets/icons/honoo_chest_blue.svg',
      'assets/icons/honoo_chest_white.svg',
      'assets/icons/honoo_chest_red.svg',
    ]) {
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is SvgPicture &&
              widget.bytesLoader is SvgAssetLoader &&
              (widget.bytesLoader as SvgAssetLoader).assetName == asset,
        ),
        findsOneWidget,
      );
    }
    expect(find.bySemanticsLabel('Blu'), findsOneWidget);
    expect(find.bySemanticsLabel('Bianchi'), findsOneWidget);
    expect(find.bySemanticsLabel('Rossi'), findsOneWidget);
    expect(find.text(BuildMetadata.displayLabel), findsNothing);
    expect(find.byTooltip('Chiudi'), findsOneWidget);
    final closeIcon = tester.widget<SvgPicture>(
      find.descendant(
        of: find.byTooltip('Chiudi'),
        matching: find.byType(SvgPicture),
      ),
    );
    expect(
      (closeIcon.bytesLoader as SvgAssetLoader).assetName,
      'assets/icons/cancella.svg',
    );
    expect(
      closeIcon.colorFilter,
      const ColorFilter.mode(HonooColor.onBackground, BlendMode.srcIn),
    );

    await tester.tap(find.byTooltip('Chiudi'));
    await tester.pumpAndSettle();
    expect(find.byType(ChestInfoDialog), findsNothing);
  });
}
