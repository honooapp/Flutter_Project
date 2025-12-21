import 'dart:math';

/// Picker casuale con memoria dell'ultimo estratto.
/// Evita ripetizioni consecutive quando possibile.
class RandomPicker<T> {
  RandomPicker({Random? random}) : _random = random ?? Random();

  final Random _random;
  T? _lastPicked;

  /// Estrae un elemento casuale dalla lista.
  ///
  /// - Se la lista è vuota → null
  /// - Se ha un solo elemento → quello
  /// - Se ha più elementi → evita ripetizione consecutiva
  T? pickOne(List<T> items, {bool avoidConsecutive = true}) {
    if (items.isEmpty) return null;

    if (items.length == 1) {
      _lastPicked = items.first;
      return items.first;
    }

    if (!avoidConsecutive) {
      final picked = items[_random.nextInt(items.length)];
      _lastPicked = picked;
      return picked;
    }

    T picked;
    int guard = 0;

    do {
      picked = items[_random.nextInt(items.length)];
      guard++;
    } while (picked == _lastPicked && guard < 20);

    _lastPicked = picked;
    return picked;
  }

  /// Da chiamare quando cambia esercizio.
  void reset() {
    _lastPicked = null;
  }
}
