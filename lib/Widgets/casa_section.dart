import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Entities/campanelli_view_data.dart';
import '../Utility/honoo_colors.dart';

class CasaSection extends StatelessWidget {
  const CasaSection({
    super.key,
    required this.casa,
    required this.isUnlocked,
    required this.scrignoAsset,
    this.onScrignoTap,
    required this.footerIconSize,
    required this.scrignoSize,
    required this.footerBottomSpacing,
    required this.width,
    required this.height,
  });

  final CasaData casa;
  final bool isUnlocked;
  final String scrignoAsset;
  final VoidCallback? onScrignoTap;
  final double footerIconSize;
  final double scrignoSize;
  final double footerBottomSpacing;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    const double designWidth = 1080;
    const double designHeight = 1920;
    final double scaleX = width / designWidth;
    final double scaleY = height / designHeight;

    Matrix4 buildTransform() {
      final List<double>? transform = casa.bgTransform;
      if (transform != null && transform.length == 16) {
        final List<double> m = List<double>.from(transform);
        m[12] *= scaleX;
        m[13] *= scaleY;
        return Matrix4.fromList(m);
      }

      final double tx = casa.bgOffsetX * scaleX;
      final double ty = casa.bgOffsetY * scaleY;
      return Matrix4.identity()
        ..translateByDouble(tx, ty, 0, 1)
        ..scaleByDouble(casa.bgScale, casa.bgScale, casa.bgScale, 1);
    }

    final Matrix4 transform = buildTransform();

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: Transform(
              transform: transform,
              alignment: Alignment.center,
              child: Image(image: casa.backgroundImage, fit: BoxFit.cover),
            ),
          ),
          if (!isUnlocked)
            Center(
              child: Text(
                'Casa chiusa',
                textAlign: TextAlign.center,
                style: GoogleFonts.lora(
                  fontSize: 18,
                  color: HonooColor.onBackground,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          Positioned(
            bottom: footerBottomSpacing,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: onScrignoTap,
                child: SizedBox(
                  width: scrignoSize,
                  height: scrignoSize,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Image.asset(scrignoAsset),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
