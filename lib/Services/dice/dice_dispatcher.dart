import 'package:honoo/Services/dice/dice_options_builder.dart';
import 'package:honoo/Widgets/dice/dice_result.dart';

import '../../IsolaDelleStorie/Utility/isola_delle_storie_content_manager.dart';

/// Decide quali opzioni del dado usare in base all'esercizio.
class DiceDispatcher {
  DiceDispatcher({DiceOptionsBuilder? builder})
      : _builder = builder ?? DiceOptionsBuilder();

  final DiceOptionsBuilder _builder;

  /// Ritorna le opzioni per un dato exerciseId (es. "3.1").
  List<DiceResult> optionsForExercise(String exerciseId) {
    switch (exerciseId) {
      case '2.5':
        return _builder.fromNumberedBoldCategories(
          IsolaDelleStoreContentManager.e25First,
        );
      case '3.1':
        return _builder.fromNumberedBoldMissions(
          IsolaDelleStoreContentManager.e31Second,
        );
      case '5.1':
        return _builder.fromNumberedBoldMissions(
          IsolaDelleStoreContentManager.e51First,
        );
      case '5.2':
        return _builder.letters();

      case '5.3':
        return _builder.letters();

      default:
        return const <DiceResult>[];
    }
  }
}
