import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ResponsiveFooterAction {
  final String asset;
  final double size;
  final String tooltip;
  final VoidCallback? onPressed;
  final String? semanticsLabel;
  final ColorFilter? colorFilter;
  final double? splashRadius;

  const ResponsiveFooterAction({
    required this.asset,
    required this.size,
    required this.tooltip,
    this.onPressed,
    this.semanticsLabel,
    this.colorFilter,
    this.splashRadius,
  });
}

class ResponsiveFooterBar extends StatelessWidget {
  const ResponsiveFooterBar({
    super.key,
    required this.actions,
    this.bottomPadding = 12,
    this.desiredGap = 24,
    this.minGap = 12,
  });

  final List<ResponsiveFooterAction> actions;
  final double bottomPadding;
  final double desiredGap;
  final double minGap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double availableWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : double.infinity;
            final double totalIconWidth = actions.fold(
              0,
              (sum, action) => sum + action.size,
            );
            final int gapCount = math.max(0, actions.length - 1);
            double gap = desiredGap;

            if (availableWidth.isFinite && gapCount > 0) {
              final double maxGap =
                  (availableWidth - totalIconWidth) / gapCount;
              if (maxGap <= minGap) {
                gap = math.max(0, maxGap);
              } else {
                gap = math.max(minGap, math.min(desiredGap, maxGap));
              }
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int index = 0; index < actions.length; index++) ...[
                  _FooterIconButton(action: actions[index]),
                  if (index < actions.length - 1) SizedBox(width: gap),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FooterIconButton extends StatelessWidget {
  const _FooterIconButton({required this.action});

  final ResponsiveFooterAction action;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      constraints: BoxConstraints.tightFor(
        width: action.size,
        height: action.size,
      ),
      padding: EdgeInsets.zero,
      icon: SvgPicture.asset(
        action.asset,
        semanticsLabel: action.semanticsLabel,
        colorFilter: action.colorFilter,
        width: action.size,
        height: action.size,
      ),
      iconSize: action.size,
      splashRadius: action.splashRadius ?? action.size * 0.5,
      tooltip: action.tooltip,
      onPressed: action.onPressed,
    );
  }
}
