/// Rappresenta un risultato generico del dado.
/// Può essere testuale o un'immagine da asset.
abstract class DiceResult {
  const DiceResult();
}

/// Risultato testuale (caso principale)
class TextDiceResult extends DiceResult {
  final String text;

  const TextDiceResult(this.text);
}

/// Risultato immagine da asset (caso speciale)
class AssetImageDiceResult extends DiceResult {
  final String assetPath;

  const AssetImageDiceResult(this.assetPath);
}
