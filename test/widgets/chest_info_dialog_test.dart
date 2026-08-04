import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Utility/build_metadata.dart';
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
    expect(chestInfoText, isNot(contains('.')));
    expect(find.text(BuildMetadata.displayLabel), findsNothing);
    expect(find.byTooltip('Chiudi'), findsOneWidget);

    await tester.tap(find.byTooltip('Chiudi'));
    await tester.pumpAndSettle();
    expect(find.byType(ChestInfoDialog), findsNothing);
  });
}
