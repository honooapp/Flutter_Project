import 'package:flutter/material.dart';

/// Stile unico per tutti i collegamenti testuali di honoo.
abstract final class HonooLinkStyle {
  static TextStyle from(TextStyle baseStyle) => baseStyle.copyWith(
    fontWeight: FontWeight.w700,
    decoration: TextDecoration.underline,
    decorationColor: baseStyle.color,
    decorationThickness: 3,
  );
}
