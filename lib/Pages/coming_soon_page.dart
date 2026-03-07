import 'package:flutter/material.dart';
import 'package:honoo/Utility/formatted_text.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Widgets/honoo_app_title.dart';
import 'package:honoo/Widgets/responsive_footer_bar.dart';
import 'package:honoo/Utility/responsive_layout.dart';
import 'package:sizer/sizer.dart';
import 'package:honoo/Utility/utility.dart';

import '../Controller/device_controller.dart';
import 'home_page.dart';
import 'placeholder_page.dart';

class ComingSoonPage extends StatefulWidget {
  const ComingSoonPage(
      {super.key,
      required this.header,
      required this.quote,
      required this.bibliography});

  final String header;
  final String quote;
  final String bibliography;

  @override
  State<ComingSoonPage> createState() => _ComingSoonPageState();
}

class _ComingSoonPageState extends State<ComingSoonPage> {
  @override
  Widget build(BuildContext context) {
    final String quote = Utility().shakespeare;
    final String bibliography = Utility().bibliography;
    final bool isPhone = DeviceController().isPhone();
    final double deviceWidth = MediaQuery.of(context).size.width;
    final ResponsiveLayoutMode layoutMode =
        ResponsiveLayout.modeForWidth(deviceWidth);
    final double footerIconSize =
        ResponsiveLayout.footerIconSizeForMode(layoutMode);
    final double footerBottomPadding =
        ResponsiveLayout.footerBottomPaddingForMode(layoutMode);
    final double safeBottom = MediaQuery.of(context).viewPadding.bottom;
    final double footerSpacing = footerBottomPadding + safeBottom;
    final double footerTopSpacing = footerSpacing / 2;
    final double footerBottomSpacing = footerSpacing - footerTopSpacing;

    return Scaffold(
      backgroundColor: HonooColor.background,
      body: Row(
        children: [
          const Spacer(),
          Container(
            constraints: BoxConstraints(
                maxWidth: isPhone ? deviceWidth : deviceWidth * 0.5),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    height: 52,
                    child: Center(
                      child: HonooAppTitle(
                        onTap: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const PlaceholderPage()),
                            (route) => false,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 5.0),
                  // Header non utilizzato: contenuto fisso da Utility
                  const SizedBox.shrink(),
                  const SizedBox(height: 30.0),
                  SizedBox(
                    width: 80.w,
                    child: Text(
                      quote,
                      style: GoogleFonts.libreFranklin(
                        color: HonooColor.wave4,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  SizedBox(
                    height: 20.h,
                    width: 80.w,
                    child: Text(
                      bibliography,
                      style: GoogleFonts.libreFranklin(
                        color: HonooColor.wave4,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(height: footerTopSpacing),
                  ResponsiveFooterBar(
                    useSafeArea: false,
                    bottomPadding: footerBottomSpacing,
                    desiredGap: ResponsiveLayout.footerGapForMode(layoutMode),
                    minGap: 16,
                    height: footerIconSize,
                    mainAxisAlignment: MainAxisAlignment.start,
                    alignment: Alignment.centerLeft,
                    actions: [
                      ResponsiveFooterAction(
                        asset: "assets/icons/home.svg",
                        semanticsLabel: 'Home',
                        size: footerIconSize,
                        splashRadius: 25,
                        tooltip: 'Home',
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const HomePage()),
                            (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
