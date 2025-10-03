import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TrackPinModel {
  final int id; // 1..9
  final double x; // 0..1 coordinate orizzontale nel viewBox del tracciato
  final double y; // 0..1 coordinate verticale nel viewBox del tracciato
  final double dx; // offset orizzontale relativo alla larghezza renderizzata
  final double dy; // offset verticale relativo all'altezza renderizzata
  final String assetSvg;
  final String hint;

  const TrackPinModel({
    required this.id,
    required this.x,
    required this.y,
    this.dx = 0,
    this.dy = 0,
    required this.assetSvg,
    required this.hint,
  });
}

class ResponsiveTrackWithPins extends StatelessWidget {
  const ResponsiveTrackWithPins({
    super.key,
    required this.trackSvgAsset,
    required this.trackAspectRatio,
    required this.pins,
    this.onPinTap,
    this.pinSizeFactor = 0.1,
    this.pinFixedSize,
    this.outerPadding,
  });

  final String trackSvgAsset;
  final double trackAspectRatio;
  final List<TrackPinModel> pins;
  final void Function(int id)? onPinTap;
  final double pinSizeFactor;
  final double? pinFixedSize;
  final EdgeInsetsGeometry? outerPadding;

  @override
  Widget build(BuildContext context) {
    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final double renderWidth =
            availableWidth.isFinite && availableWidth > 0 ? availableWidth : MediaQuery.of(context).size.width;
        final double safeAspectRatio = trackAspectRatio <= 0 ? 1 : trackAspectRatio;
        final double renderHeight = renderWidth / safeAspectRatio;

        final double baseSize = math.min(renderWidth, renderHeight);
        final double pinVisualSize = pinFixedSize ?? (baseSize * pinSizeFactor).clamp(24.0, 160.0);
        final double hitTarget = math.max(pinVisualSize, 40.0);

        return SizedBox(
          width: renderWidth,
          height: renderHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: SvgPicture.asset(trackSvgAsset, fit: BoxFit.fill),
              ),
              ...pins.map((pin) {
                final double centerX = (pin.x * renderWidth) + (pin.dx * renderWidth);
                final double centerY = (pin.y * renderHeight) + (pin.dy * renderHeight);
                final double left = centerX - (hitTarget / 2);
                final double top = centerY - (hitTarget / 2);
                final bool enabled = onPinTap != null;

                return Positioned(
                  left: left,
                  top: top,
                  child: Tooltip(
                    message: pin.hint,
                    child: Semantics(
                      label: pin.hint,
                      button: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: enabled ? () => onPinTap!(pin.id) : null,
                        child: SizedBox(
                          width: hitTarget,
                          height: hitTarget,
                          child: Center(
                            child: SvgPicture.asset(
                              pin.assetSvg,
                              width: pinVisualSize,
                              height: pinVisualSize,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );

    if (outerPadding != null) {
      content = Padding(padding: outerPadding!, child: content);
    }

    return content;
  }
}
