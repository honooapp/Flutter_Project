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
    final infoText = tester.widget<RichText>(
      find.descendant(
        of: find.byType(ChestInfoDialog),
        matching: find.byType(RichText),
      ),
    );
    expect(
      infoText.text.toPlainText(includeSemanticsLabels: false),
      "Questo è il tuo Scrigno\n\n"
      "Qui sono custoditi\n"
      "gli honoo e gli hinoo\n"
      "che hai scritto\n"
      "\uFFFC\n\n"
      "quelli che hai salvato dalla Luna\n"
      "\uFFFC\n\n"
      "e quelli che hai ricevuto\n"
      "\uFFFC\n\n"
      "Scorri verso destra\n"
      "per rivedere\n"
      "quello che hai scritto\n"
      "e quello che hai salvato\n\n"
      "Scorri verso il basso\n"
      "per seguire\n"
      "le conversazioni fra\n\n"
      "quello che hai salvato\n"
      "dalla Luna\n"
      "\uFFFC\n\n"
      "la tua risposta,\n"
      "\uFFFC\n\n"
      "e, se arriva,\n"
      "la risposta alla tua risposta\n"
      "\uFFFC",
    );
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
        findsNWidgets(2),
      );
    }
    expect(find.bySemanticsLabel('Blu'), findsNWidgets(2));
    expect(find.bySemanticsLabel('Bianchi'), findsNWidgets(2));
    expect(find.bySemanticsLabel('Rossi'), findsNWidgets(2));
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
