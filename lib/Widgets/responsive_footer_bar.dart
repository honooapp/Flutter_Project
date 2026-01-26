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
  final Widget? icon;

  const ResponsiveFooterAction({
    required this.asset,
    required this.size,
    required this.tooltip,
    this.onPressed,
    this.semanticsLabel,
    this.colorFilter,
    this.splashRadius,
    this.icon,
  });
}

class ResponsiveFooterBar extends StatelessWidget {
  const ResponsiveFooterBar({
    super.key,
    required this.actions,
    this.bottomPadding = 12,
    this.desiredGap = 24,
    this.minGap = 12,
    this.height = 60,
    this.lockGapWhenPossible = false,
    this.useSafeArea = true,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.alignment = Alignment.center,
  });

  final List<ResponsiveFooterAction> actions;
  final double bottomPadding;
  final double desiredGap;
  final double minGap;
  final double height;
  final bool lockGapWhenPossible;
  final bool useSafeArea;
  final MainAxisAlignment mainAxisAlignment;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final bool isPhone = MediaQuery.of(context).size.shortestSide < 600;
    final double effectiveDesiredGap = isPhone ? desiredGap + 4 : desiredGap;
    final double effectiveMinGap = isPhone ? minGap + 2 : minGap;
    final Widget bar = Padding(
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
          double gap = effectiveDesiredGap;

          if (availableWidth.isFinite && gapCount > 0) {
            final double maxGap =
                (availableWidth - totalIconWidth) / gapCount;
            if (lockGapWhenPossible && maxGap >= effectiveDesiredGap) {
              gap = effectiveDesiredGap;
            } else if (maxGap <= effectiveMinGap) {
              gap = math.max(0, maxGap);
            } else {
              gap = math.max(
                effectiveMinGap,
                math.min(effectiveDesiredGap, maxGap),
              );
            }
          }

          return SizedBox(
            height: height,
            child: Align(
              alignment: alignment,
              child: Row(
                mainAxisAlignment: mainAxisAlignment,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int index = 0; index < actions.length; index++) ...[
                    _FooterIconButton(action: actions[index]),
                    if (index < actions.length - 1) SizedBox(width: gap),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );

    if (!useSafeArea) {
      return bar;
    }

    return SafeArea(top: false, child: bar);
  }
}

class _FooterIconButton extends StatelessWidget {
  const _FooterIconButton({required this.action});

  final ResponsiveFooterAction action;

  @override
  Widget build(BuildContext context) {
    final Widget iconWidget = action.icon ??
        SvgPicture.asset(
          action.asset,
          semanticsLabel: action.semanticsLabel,
          colorFilter: action.colorFilter,
          width: action.size,
          height: action.size,
        );

    return IconButton(
      constraints: BoxConstraints.tightFor(
        width: action.size,
        height: action.size,
      ),
      padding: EdgeInsets.zero,
      icon: iconWidget,
      iconSize: action.size,
      splashRadius: action.splashRadius ?? action.size * 0.5,
      tooltip: action.tooltip,
      onPressed: action.onPressed,
    );
  }
}
