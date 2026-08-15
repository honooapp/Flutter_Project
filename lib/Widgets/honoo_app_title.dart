import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Utility/utility.dart';

import '../Pages/placeholder_page.dart';

class HonooAppTitle extends StatelessWidget {
  const HonooAppTitle({super.key, this.onTap, this.color, this.fontSize = 28});

  final VoidCallback? onTap;
  final Color? color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final VoidCallback effectiveOnTap =
        onTap ??
        () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const PlaceholderPage()),
            (route) => false,
          );
        };
    final text = AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      style: GoogleFonts.libreFranklin(
        color: color ?? HonooColor.secondary,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      ),
      child: Text(Utility().appName, textAlign: TextAlign.center),
    );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: effectiveOnTap,
      child: Semantics(
        button: true,
        label: 'Apri la pagina honoo',
        child: text,
      ),
    );
  }
}
