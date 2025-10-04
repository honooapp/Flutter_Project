import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:honoo/UI/HonooCard.dart';
import 'package:honoo/Entities/Honoo.dart';

void main() {
  testGoldens('HonooCard golden default (con Honoo posizionale)', (tester) async {
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
  });
}
