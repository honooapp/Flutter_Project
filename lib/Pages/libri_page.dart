import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Utility/utility.dart';
import 'package:honoo/Widgets/honoo_standard_page.dart';

class LibriPage extends StatelessWidget {
  const LibriPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle style = GoogleFonts.arvo(
      color: HonooColor.onBackground,
      fontSize: 18,
      fontWeight: FontWeight.w200,
      height: 1.3,
    );

    return HonooStandardPage(
      contentWidthFactor: 0.45,
      child: Text(
        Utility().libriText,
        style: style,
        textAlign: TextAlign.center,
      ),
    );
  }
}

