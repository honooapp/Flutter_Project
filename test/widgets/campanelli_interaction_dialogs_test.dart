import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Entities/casa_share_mode.dart';
import 'package:honoo/Pages/casa_share_selection_page.dart';

void main() {
  testWidgets('pagina responsive salva una selezione multipla', (tester) async {
    Set<CasaShareMode>? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await Navigator.of(context).push<Set<CasaShareMode>>(
                MaterialPageRoute(
                  builder: (_) => const CasaShareSelectionPage(),
                ),
              );
            },
            child: const Text('Apri'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();
    expect(find.text('cosa vuoi mostrare?'), findsOneWidget);
    expect(find.byKey(const ValueKey('house-share-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('house-share-moon')), findsOneWidget);
    expect(find.byKey(const ValueKey('house-share-all')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('house-share-home')));
    await tester.tap(find.byKey(const ValueKey('house-share-moon')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('house-share-confirm')));
    await tester.pumpAndSettle();

    expect(result, {CasaShareMode.home, CasaShareMode.moon});
  });

  testWidgets('icone restano visibili su viewport desktop', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: CasaShareSelectionPage()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('house-share-confirm')), findsOneWidget);
    expect(find.byTooltip('honoo e hinoo di casa'), findsOneWidget);
    expect(find.byTooltip('honoo e hinoo dalla luna'), findsOneWidget);
    expect(find.byTooltip('tutto'), findsOneWidget);
  });
}
