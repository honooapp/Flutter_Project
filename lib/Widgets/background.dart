import 'package:flutter/material.dart';

import 'smooth_image.dart';

class Background extends StatelessWidget {
  final Widget child;
  final String imagePath;

  const Background({
    super.key,
    required this.child,
    this.imagePath = "assets/background.webp",
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        SmoothImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
          placeholderColor: const Color(0xFF010E22),
        ),
        child,
      ],
    );
  }
}
