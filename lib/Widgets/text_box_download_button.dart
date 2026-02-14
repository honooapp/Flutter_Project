import 'package:flutter/material.dart';

class TextBoxDownloadButton extends StatelessWidget {
  const TextBoxDownloadButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'download',
    this.size = 30,
  });

  final VoidCallback onPressed;
  final String tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(size / 2),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(size / 2),
            ),
            child: Icon(
              Icons.download_outlined,
              size: size * 0.6,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
