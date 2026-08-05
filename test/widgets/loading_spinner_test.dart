import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Widgets/loading_spinner.dart';

void main() {
  testWidgets('usa load.svg in nero per impostazione predefinita', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LoadingSpinner(size: 32))),
    );

    final spinner = tester.widget<LoadingSpinner>(find.byType(LoadingSpinner));
    final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));

    expect(spinner.color, Colors.black);
    expect(svg.width, 32);
    expect(svg.height, 32);
    expect(svg.colorFilter, isNotNull);
  });

  test('i loader dell app non usano indicatori Material predefiniti', () {
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      expect(
        source,
        isNot(contains('CircularProgressIndicator')),
        reason: '${file.path} deve usare LoadingSpinner con load.svg',
      );
      expect(
        source,
        isNot(contains('LinearProgressIndicator')),
        reason: '${file.path} deve usare LoadingSpinner con load.svg',
      );
      expect(
        source,
        isNot(contains('CupertinoActivityIndicator')),
        reason: '${file.path} deve usare LoadingSpinner con load.svg',
      );
    }
  });
}
