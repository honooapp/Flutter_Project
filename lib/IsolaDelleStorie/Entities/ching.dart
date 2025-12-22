// lib/Entities/ching_entry.dart
import 'package:flutter/foundation.dart';

@immutable
class Ching {
  final int number; // 1..64
  final String hanzi; // es. "小畜"
  final String titleIt; // es. "La Forza domatrice del piccolo"
  final String
      assetPath; // es. "assets/icons/ching/svg/ching_9_La Forza domatrice del piccolo.svg"

  const Ching({
    required this.number,
    required this.hanzi,
    required this.titleIt,
    required this.assetPath,
  });
}
