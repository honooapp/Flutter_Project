import 'package:flutter/material.dart';

import '../../Entities/hinoo.dart';
import '../../UI/hinoo_viewer.dart';
import '../../Utility/honoo_colors.dart';
import '../../Utility/responsive_layout.dart';
import '../../Widgets/honoo_app_title.dart';
import '../../Widgets/responsive_footer_bar.dart';

class PendingHinooPage extends StatelessWidget {
  const PendingHinooPage({super.key, required this.draft});

  final HinooDraft draft;

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
          final double footerIconSize =
              ResponsiveLayout.footerIconSizeForMode(layoutMode);
          final double footerGap =
              ResponsiveLayout.footerGapForMode(layoutMode);
          final double footerBottomPadding =
              ResponsiveLayout.footerBottomPaddingForMode(layoutMode);
          final double footerSpacing = footerBottomPadding + safeBottom;
          final double footerTopSpacing = footerSpacing / 2;
          final double footerBottomSpacing = footerSpacing - footerTopSpacing;
          const double headerH = 52;
          final double targetMaxW = viewW;
          final double footerReserved =
              footerIconSize + footerTopSpacing + footerBottomSpacing;
          final double availableH =
              (viewH - headerH - footerReserved).clamp(0.0, double.infinity);

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
                    width: targetMaxW,
                    height: availableH,
                    child: HinooViewer(
                      draft: draft,
                      maxHeight: availableH,
                      maxWidth: targetMaxW,
                    ),
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
