import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ColoreTestoOverlay extends StatelessWidget {
  const ColoreTestoOverlay({
    super.key,
    required this.onPick,
  });

  final ValueChanged<Color> onPick;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Scegli il colore del testo',
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ColorDot(color: Colors.white, onTap: () => onPick(Colors.white)),
              const SizedBox(width: 16),
              _ColorDot(color: Colors.black, onTap: () => onPick(Colors.black)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color, required this.onTap});
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }
}
