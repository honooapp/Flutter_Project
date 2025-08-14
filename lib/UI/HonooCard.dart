import 'package:flutter/material.dart';
import 'package:honoo/Utility/HonooColors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../Entites/Honoo.dart';

class HonooCard extends StatelessWidget {
  final Honoo honoo;

  const HonooCard({super.key, required this.honoo});

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.of(context).size.shortestSide < 600;
    final maxWidth = MediaQuery.of(context).size.width;
    final double cardWidth = isPhone ? maxWidth * 0.9 : maxWidth * 0.5;
    return Center(
      child: SizedBox(
        width: cardWidth,
        child: AspectRatio(
          aspectRatio: 1 / 2.2,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final double imageSize = width;
              final double frameHeight = imageSize / 2;

              // Sfondo dinamico
              final Color backgroundColor =
              honoo.type == HonooType.moon
                  ? HonooColor.tertiary
                  : honoo.type == HonooType.answer
                  ? HonooColor.secondary
                  : HonooColor.background;

              return Card(
                color: backgroundColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Box testo
                    SizedBox(
                      width: width / 2,
                      height: frameHeight,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black12),
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            honoo.text,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.arvo(
                              fontSize: 12.sp,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Immagine quadrata
                    SizedBox(
                      width: imageSize,
                      height: imageSize,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Image.network(
                          honoo.image,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
