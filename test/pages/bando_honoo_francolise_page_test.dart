import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Pages/bando_honoo_francolise_page.dart';
import 'package:honoo/Pages/placeholder_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'la landing apre il Bando Francolise dal link e dalla sua icona',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: PlaceholderPage()));
      await tester.pumpAndSettle();

      final link = find.text('Bando honoo\nper Francolise');
      final icon = find.byIcon(Icons.castle);
      expect(link, findsOneWidget);
      expect(icon, findsOneWidget);

      await tester.ensureVisible(link);
      await tester.tap(link);
      await tester.pumpAndSettle();
      expect(find.byType(BandoHonooFrancolisePage), findsOneWidget);

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      await tester.ensureVisible(icon);
      await tester.tap(icon);
      await tester.pumpAndSettle();
      expect(find.byType(BandoHonooFrancolisePage), findsOneWidget);
    },
  );

  testWidgets('il Bando Francolise mostra il testo completo nello stile app', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: BandoHonooFrancolisePage()),
    );
    await tester.pumpAndSettle();

    final text = tester.widget<Text>(find.byKey(const Key('section_text')));
    expect(text.data, BandoHonooFrancolisePage.bandoText);
    expect(text.textAlign, TextAlign.center);
    expect(text.style?.fontSize, 18);
    expect(text.style?.height, 1.3);
    expect(text.data, startsWith('Bando honoo\nper Francolise\n\n'));
    expect(text.data, contains('del 31 agosto 2026'));
    expect(text.data, contains('Behavior-Driven Development'));
    expect(text.data, contains('che ho citato'));
    expect(text.data, isNot(contains('&#x20;')));
  });
}
