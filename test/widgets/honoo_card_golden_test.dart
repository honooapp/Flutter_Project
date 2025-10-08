import 'package:flutter/material.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:honoo/UI/honoo_card.dart';
import 'package:honoo/Entities/honoo.dart';

void main() {
  testGoldens(
    'HonooCard golden default (con Honoo posizionale)',
    (tester) async {
      await loadAppFonts();

      final honoo = Honoo(
        1,
        '“Ciao luna”',
        '',
        '2024-01-01T00:00:00Z',
        '2024-01-01T00:00:00Z',
        'u1',
        HonooType.personal,
      );

      final widget = MaterialApp(
        home: Scaffold(
          body: Center(child: HonooCard(honoo: honoo)),
        ),
      );

      await tester.pumpWidgetBuilder(widget);
      await screenMatchesGolden(tester, 'honoo_card_default');
    },
    tags: ['golden'], // 👈 così Codex lo salta
  );
}
