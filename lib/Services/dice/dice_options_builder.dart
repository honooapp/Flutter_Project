import 'package:honoo/Widgets/dice/dice_result.dart';

/// Responsabilità:
/// costruire una lista di DiceResult in base a una richiesta.
class DiceOptionsBuilder {
  /// Caso base: lista di stringhe semplici
  List<DiceResult> fromStrings(List<String> values) {
    final List<DiceResult> results = [];

    for (final raw in values) {
      final String cleaned = _cleanString(raw);
      if (cleaned.isEmpty) continue;
      results.add(TextDiceResult(cleaned));
    }

    return results;
  }

  List<DiceResult> fromNumberedBoldCategories(String rawText) {
    final List<DiceResult> results = [];

    // Regex:
    // - cattura un numero (una o due cifre)
    // - seguito da spazi/newline
    // - seguito da <b>TESTO<b>
    final RegExp categoryRegex =
        RegExp(r'(\d{1,2})\s*<b>([^<]+)<b>', multiLine: true);

    final matches = categoryRegex.allMatches(rawText);

    for (final match in matches) {
      final String number = match.group(1)!.trim();
      final String label = match.group(2)!.trim();

      results.add(
        TextDiceResult('$number\n$label'),
      );
    }

    return results;
  }

  /// Costruisce opzioni del dado a partire da UNA stringa multilinea.
  List<DiceResult> fromMultilineCountText(String rawText) {
    final List<DiceResult> results = [];

    final lines =
        rawText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty);

    for (final line in lines) {
      final parts = line.split(RegExp(r'\s+'));

      if (parts.length < 2) continue;

      final String number = parts.first;
      final String label = parts.sublist(1).join(' ');

      results.add(
        TextDiceResult('$number\n$label'),
      );
    }

    return results;
  }

  /// Estrae missioni numerate da un testo lungo con <b>.
  /// Supporta missioni su più righe.
  ///
  /// Output esempio:
  /// "21\nCamminare mano\nnella mano"
  List<DiceResult> fromNumberedBoldMissions(String rawText) {
    final List<DiceResult> results = [];

    // Normalizziamo newline
    final lines = rawText
        .replaceAll('\r\n', '\n')
        .split('\n')
        .map((l) => l.trim())
        .toList();

    String? currentNumber;
    final List<String> currentParts = [];

    final numberRegex = RegExp(r'^\d+$');
    final boldRegex = RegExp(r'^<b>(.*)<b>$');

    void flushCurrent() {
      if (currentNumber == null || currentParts.isEmpty) return;

      final text = currentParts.join('\n');
      results.add(TextDiceResult('$currentNumber\n$text'));
    }

    for (final line in lines) {
      // Nuovo numero → nuova missione
      if (numberRegex.hasMatch(line)) {
        flushCurrent();
        currentNumber = line;
        currentParts.clear();
        continue;
      }

      // Riga <b>...</b>
      final boldMatch = boldRegex.firstMatch(line);
      if (boldMatch != null) {
        final content = boldMatch.group(1)?.trim();
        if (content != null && content.isNotEmpty) {
          currentParts.add(content);
        }
      }
    }

    // Ultima missione
    flushCurrent();

    return results;
  }

  /// Caso 2: genera un array di lettere (A–Z).
  /// Utile per esercizi che richiedono una lettera casuale.
  List<DiceResult> letters({
    bool uppercase = true,
  }) {
    final List<DiceResult> results = [];

    for (int i = 0; i < 26; i++) {
      final String letter = String.fromCharCode((uppercase ? 65 : 97) + i);

      results.add(TextDiceResult(letter));
    }

    return results;
  }

  String _cleanString(String input) {
    return input
        .replaceAll('\r\n', '\n')
        .replaceAll(RegExp(r'\n{2,}'), '\n')
        .trim();
  }

  /// Caso 3: immagini da asset
  List<DiceResult> fromAssets(List<String> assetPaths) {
    // IMPLEMENTEREMO DOPO
    return [];
  }
}
