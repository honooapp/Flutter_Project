import 'package:flutter/material.dart';

import 'smooth_image.dart';

class Background extends StatelessWidget {
  final Widget child;
  final String imagePath;
  final Color placeholderColor;
  final Duration fadeDuration;

  const Background({
    super.key,
    required this.child,
    this.imagePath = "assets/background.webp",
    this.placeholderColor = const Color(0xFF010E22),
    this.fadeDuration = const Duration(milliseconds: 280),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        SmoothImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
          placeholderColor: placeholderColor,
          fadeDuration: fadeDuration,
        ),
        child,
      ],
    );
  }
}
