import 'package:flutter/material.dart';
import 'package:honoo/Controller/device_controller.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Utility/responsive_layout.dart';
import 'package:honoo/Widgets/background.dart';
import 'package:honoo/Widgets/honoo_app_title.dart';
import 'package:honoo/Widgets/responsive_footer_bar.dart';

class HonooStandardPage extends StatelessWidget {
  const HonooStandardPage({
    super.key,
    required this.child,
    this.contentWidthFactor = 0.45,
    this.minDesktopWidth = 420.0,
    this.horizontalPadding,
    this.onHome,
  });

  final Widget child;
  final double contentWidthFactor;
  final double minDesktopWidth;
  final EdgeInsets? horizontalPadding;
  final VoidCallback? onHome;

  @override
  Widget build(BuildContext context) {
    final bool isPhone = DeviceController().isPhone();
    final double screenWidth = MediaQuery.of(context).size.width;
    final ResponsiveLayoutMode layoutMode =
        ResponsiveLayout.modeForWidth(screenWidth);

    final double footerIconSize =
        ResponsiveLayout.footerIconSizeForMode(layoutMode);
    final double footerBottomPadding =
        ResponsiveLayout.footerBottomPaddingForMode(layoutMode);
    final double footerGap = ResponsiveLayout.footerGapForMode(layoutMode);
    final double safeBottom = MediaQuery.of(context).viewPadding.bottom;
    final double footerSpacing = footerBottomPadding + safeBottom;
    final double footerTopSpacing = footerSpacing / 2;
    final double footerBottomSpacing = footerSpacing - footerTopSpacing;

    final double footerSidePadding;
    switch (layoutMode) {
      case ResponsiveLayoutMode.mobile:
        footerSidePadding = 16;
        break;
      case ResponsiveLayoutMode.tablet:
        footerSidePadding = 20;
        break;
      case ResponsiveLayoutMode.desktop:
      case ResponsiveLayoutMode.wideDesktop:
      case ResponsiveLayoutMode.largeDesktop:
        footerSidePadding = 24;
        break;
    }

    final double contentWidth = isPhone
        ? screenWidth
        : () {
            final double target = screenWidth * contentWidthFactor;
            return target < minDesktopWidth ? minDesktopWidth : target;
          }();

    final Widget content = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(
            height: 52,
            child: Center(child: HonooAppTitle()),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: SizedBox(
                width: contentWidth,
                child: Padding(
                  padding: horizontalPadding ?? EdgeInsets.zero,
                  child: child,
                ),
              ),
            ),
          ),
          SizedBox(height: footerTopSpacing),
          Padding(
            padding: EdgeInsets.only(left: footerSidePadding),
            child: ResponsiveFooterBar(
              useSafeArea: false,
              bottomPadding: footerBottomSpacing,
              desiredGap: footerGap,
              minGap: 16,
              height: footerIconSize,
              mainAxisAlignment: MainAxisAlignment.start,
              alignment: Alignment.centerLeft,
              actions: [
                ResponsiveFooterAction(
                  asset: 'assets/icons/home.svg',
                  semanticsLabel: 'Home',
                  size: footerIconSize,
                  tooltip: 'Home',
                  onPressed: onHome ?? () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final Widget pageBody = Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          Expanded(child: Container()),
          Align(
            alignment: Alignment.center,
            child: Container(
              color: HonooColor.background.withOpacity(isPhone ? 1 : 0.7),
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: content,
            ),
          ),
          Expanded(child: Container()),
        ],
      ),
    );

    return isPhone ? pageBody : Background(child: pageBody);
  }
}

