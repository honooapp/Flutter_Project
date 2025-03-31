import 'package:flutter/material.dart';

class Background extends StatelessWidget {
  final Widget child;
  final String imagePath;

  const Background({
    super.key,
    required this.child,
    this.imagePath = "assets/sirenaepalombaro.jpg",
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Image.asset(
          imagePath,
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          fit: BoxFit.cover,
        ),
        child,
      ],
    );
  }
}
