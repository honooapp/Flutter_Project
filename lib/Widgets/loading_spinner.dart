import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoadingSpinner extends StatefulWidget {
  const LoadingSpinner({
    super.key,
    this.size = 50.0,
    this.color,
    this.semanticsLabel,
    this.rotationDuration = const Duration(milliseconds: 900),
  });

  final double size;
  final Color? color;
  final String? semanticsLabel;
  final Duration rotationDuration;

  @override
  State<LoadingSpinner> createState() => _LoadingSpinnerState();
}

class _LoadingSpinnerState extends State<LoadingSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.rotationDuration,
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant LoadingSpinner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rotationDuration != widget.rotationDuration) {
      _controller
        ..duration = widget.rotationDuration
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String semantics = widget.semanticsLabel ?? 'Caricamento';

    Widget spinner = SvgPicture.asset(
      'assets/icons/load.svg',
      width: widget.size,
      height: widget.size,
      semanticsLabel: semantics,
      colorFilter: widget.color != null
          ? ColorFilter.mode(widget.color!, BlendMode.srcIn)
          : null,
    );

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double angle = _controller.value * 2 * math.pi;
          return Transform.rotate(
            angle: angle,
            child: child,
          );
        },
        child: spinner,
      ),
    );
  }
}
