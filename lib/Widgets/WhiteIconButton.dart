import 'package:flutter/material.dart';

class WhiteIconButton extends StatelessWidget {
  const WhiteIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    super.key,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: Colors.white),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.all(8),
        shape: const CircleBorder(),
        elevation: 2,
      ),
    );
  }
}

