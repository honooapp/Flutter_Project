import 'package:flutter/material.dart';

import '../../Entities/honoo.dart';
import '../../UI/honoo_card.dart';
import '../../Utility/honoo_colors.dart';
import '../../Utility/responsive_layout.dart';
import '../../Widgets/honoo_app_title.dart';
import '../../Widgets/responsive_footer_bar.dart';

class PendingHonooPage extends StatelessWidget {
  const PendingHonooPage({super.key, required this.honoo});

  final Honoo honoo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HonooColor.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double viewW = constraints.maxWidth;
          final double viewH = constraints.maxHeight;
          final double safeBottom = MediaQuery.of(context).viewPadding.bottom;
          final layoutMode = ResponsiveLayout.modeForWidth(viewW);
          final double footerIconSize = ResponsiveLayout.footerIconSizeForMode(
            layoutMode,
          );
          final double footerGap = ResponsiveLayout.footerGapForMode(
            layoutMode,
          );
          final double footerBottomPadding =
              ResponsiveLayout.footerBottomPaddingForMode(layoutMode);
          final double footerSpacing = footerBottomPadding + safeBottom;
          final double footerTopSpacing = footerSpacing / 2;
          final double footerBottomSpacing = footerSpacing - footerTopSpacing;
          const double headerH = 52;
          final double targetMaxW = ResponsiveLayout.contentMaxWidth(viewW);
          final double footerReserved =
              footerIconSize + footerTopSpacing + footerBottomSpacing;
          final double availableH = (viewH - headerH - footerReserved).clamp(
            0.0,
            double.infinity,
          );
          final HonooBuilderMetrics metrics =
              ResponsiveLayout.honooBuilderMetrics(
                availableHeight: availableH,
                maxWidth: targetMaxW,
                mode: layoutMode,
              );

          return Column(
            children: [
              SizedBox(
                height: headerH,
                child: Center(
                  child: HonooAppTitle(
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: metrics.width,
                    height: metrics.height,
                    child: HonooCard(honoo: honoo),
                  ),
                ),
              ),
              SizedBox(height: footerTopSpacing),
              ResponsiveFooterBar(
                useSafeArea: false,
                bottomPadding: footerBottomSpacing,
                desiredGap: footerGap,
                minGap: 16,
                height: footerIconSize,
                actions: [
                  ResponsiveFooterAction(
                    asset: "assets/icons/cancella.svg",
                    semanticsLabel: 'Annulla',
                    size: footerIconSize,
                    colorFilter: const ColorFilter.mode(
                      HonooColor.onBackground,
                      BlendMode.srcIn,
                    ),
                    splashRadius: 25,
                    tooltip: 'Non ora',
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  ResponsiveFooterAction(
                    asset: "assets/icons/ok.svg",
                    semanticsLabel: 'OK',
                    size: footerIconSize,
                    splashRadius: 25,
                    tooltip: 'Apri',
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
