import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Utility/utility.dart';

class HonooAppTitle extends StatelessWidget {
  const HonooAppTitle({super.key, this.onTap, this.color, this.fontSize = 28});

  final VoidCallback? onTap;
  final Color? color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
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

    if (onTap == null) {
      return text;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: Semantics(button: true, label: 'Home', child: text),
    );
  }
}
