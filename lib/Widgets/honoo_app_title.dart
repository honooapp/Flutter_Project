import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Utility/utility.dart';

class HonooAppTitle extends StatelessWidget {
  const HonooAppTitle({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      Utility().appName,
      style: GoogleFonts.libreFranklin(
        color: HonooColor.secondary,
        fontSize: 30,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    );

    if (onTap == null) {
      return text;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: Semantics(
        button: true,
        label: 'Home',
        child: text,
      ),
    );
  }
}
