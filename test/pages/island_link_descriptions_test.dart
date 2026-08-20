import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/IsolaDelleStorie/Entities/exercise.dart';
import 'package:honoo/IsolaDelleStorie/Pages/exercise_page.dart';
import 'package:honoo/Utility/formatted_text.dart';
import 'package:sizer/sizer.dart';

void main() {
  testWidgets('i testi aperti dai link dell’Isola rimuovono i punti finali', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    final exercise = Exercise(
      '1',
      1,
      'Grotta delle Rondini',
      'Primo paragrafo.\n\nAttendi...',
      'assets/icons/isoladellestorie/backgrounds/1grottarondini.png',
      exerciseDescriptionMore: '<b>Ultimo paragrafo.<b>',
    );

    await tester.pumpWidget(
      Sizer(
        builder: (context, orientation, deviceType) =>
            MaterialApp(home: ExercisePage(exercise: exercise)),
      ),
    );
    await tester.pump();

    final descriptions = tester
        .widgetList<FormattedText>(find.byType(FormattedText))
        .map((widget) => widget.inputText)
        .toList();

    expect(descriptions, <String>[
      'Primo paragrafo\n\nAttendi...',
      '<b>Ultimo paragrafo<b>',
    ]);
    expect(tester.takeException(), isNull);
  });
}
