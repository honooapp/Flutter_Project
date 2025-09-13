import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CambiaSfondoOverlay extends StatelessWidget {
  const CambiaSfondoOverlay({
    super.key,
    required this.onTapChange,
  });

  final VoidCallback onTapChange;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: onTapChange,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.50),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'cambia lo sfondo del tuo hinoo',
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
