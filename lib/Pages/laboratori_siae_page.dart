import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Controller/device_controller.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Utility/responsive_layout.dart';
import 'package:honoo/Widgets/honoo_app_title.dart';
import 'package:honoo/Widgets/responsive_footer_bar.dart';
import 'package:honoo/Widgets/background.dart';
import 'package:url_launcher/url_launcher.dart';

import 'home_page.dart';
import 'laboratori_noi_e_loro_page.dart';

class LaboratoriSiaePage extends StatelessWidget {
  const LaboratoriSiaePage({super.key});

  static const String _bodyAfterLinks =
      "\n"
      "è stato selezionato\n"
      "per il contributo Siae,\n"
      "che ha permesso a\n"
      "Venceslao Cembalo,\n"
      "Angelo Grimaldi,\n"
      "Alessandro Bottone,\n"
      "Agnese Fornito,\n"
      "Antonio Sodorino,\n"
      "Giacomo Carruolo,\n"
      "e Daniele Tammaro,\n"
      "di realizzare il progetto\n"
      "con gli studenti\n"
      "dell’Istituto Statale\n"
      "Alessandro Volta\n"
      "di Aversa\n"
      "e con i loro tutor\n"
      "Gabriella Maria Corvino,\n"
      "Luisa Isabella Coscione,\n"
      "Immacolata Iorio,\n"
      "Filomena Reccia,\n"
      "Vincenzo  Fusco,\n"
      "Agostino  Gravante,\n"
      "Pasqualina D’Agostino\n\n"
      "Sì,\n"
      "nel 2025\n"
      "honoo ha partecipato\n"
      "a un Bando Siae\n"
      "E ha vinto\n\n";

  @override
  Widget build(BuildContext context) {
    final bool isPhone = DeviceController().isPhone();
    final double screenWidth = MediaQuery.of(context).size.width;
    final ResponsiveLayoutMode layoutMode = ResponsiveLayout.modeForWidth(
      screenWidth,
    );
    final double footerIconSize = ResponsiveLayout.footerIconSizeForMode(
      layoutMode,
    );
    final double footerBottomPadding =
        ResponsiveLayout.footerBottomPaddingForMode(layoutMode);
    final double safeBottom = MediaQuery.of(context).viewPadding.bottom;
    final double footerSpacing = footerBottomPadding + safeBottom;
    final double footerTopSpacing = footerSpacing / 2;
    final double footerBottomSpacing = footerSpacing - footerTopSpacing;
    final double footerSidePadding = () {
      switch (layoutMode) {
        case ResponsiveLayoutMode.mobile:
          return 16.0;
        case ResponsiveLayoutMode.tablet:
          return 20.0;
        case ResponsiveLayoutMode.desktop:
        case ResponsiveLayoutMode.wideDesktop:
        case ResponsiveLayoutMode.largeDesktop:
          return 24.0;
      }
    }();

    final double contentWidth = isPhone
        ? screenWidth
        : () {
            const double minDesktopWidth = 420.0;
            final double target = screenWidth * 0.4;
            return target < minDesktopWidth ? minDesktopWidth : target;
          }();

    final TextStyle baseTextStyle = GoogleFonts.arvo(
      color: HonooColor.onBackground,
      fontSize: 18,
      fontWeight: FontWeight.w200,
      height: 1.3,
    );

    final List<InlineSpan> spans = [
      TextSpan(text: 'Laboratori teatrali\n\n', style: baseTextStyle),
      TextSpan(text: 'honoo e ', style: baseTextStyle),
      TextSpan(
        text: 'Crocopie',
        style: baseTextStyle.copyWith(
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            final uri = Uri.parse('https://crocopie.com');
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          },
      ),
      TextSpan(
        text:
            '\nhanno partecipato\nal Bando\nSiae Per Chi Crea 2025\ncon il progetto\n',
        style: baseTextStyle,
      ),
      TextSpan(
        text: 'Noi e loro',
        style: baseTextStyle.copyWith(
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LaboratoriNoiELoroPage()),
            );
          },
      ),
      TextSpan(text: '\n\nNoi e loro', style: baseTextStyle),
      TextSpan(text: _bodyAfterLinks, style: baseTextStyle),
    ];

    final Widget content = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: 52, child: Center(child: HonooAppTitle())),
          Expanded(
            child: SingleChildScrollView(
              child: SizedBox(
                width: contentWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: RichText(
                    key: const Key('section_text'),
                    textAlign: TextAlign.center,
                    text: TextSpan(children: spans),
                  ),
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
                      MaterialPageRoute(builder: (_) => const HomePage()),
                      (route) => false,
                    );
                  },
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
              color: HonooColor.background.withValues(alpha: isPhone ? 1 : 0.7),
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
