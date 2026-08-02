import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Pages/new_hinoo_page.dart';
import '../Pages/new_honoo_page.dart';
import '../Utility/honoo_colors.dart';

class ComposerLauncher {
  const ComposerLauncher._();

  static Future<void> open(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const ComposerOnboardingPage(),
      ),
    );
  }
}

class ComposerOnboardingPage extends StatelessWidget {
  const ComposerOnboardingPage({super.key});

  void _dismiss(BuildContext context) => Navigator.of(context).pop();

  Future<void> _openHonooComposer(BuildContext context) async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => const NewHonooPage()));
  }

  Future<void> _openHinooComposer(BuildContext context) async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => const NewHinooPage()));
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final textScaler = mediaQuery.textScaler.clamp(
      minScaleFactor: 0.8,
      maxScaleFactor: 1.5,
    );

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: textScaler),
      child: Scaffold(
        key: const Key('composer_onboarding_page'),
        backgroundColor: HonooColor.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 420
                  ? 20.0
                  : 40.0;
              final imageWidth = math.min(
                constraints.maxWidth - (horizontalPadding * 2),
                300.0,
              );
              final exampleHeight = (constraints.maxHeight * 0.32).clamp(
                180.0,
                280.0,
              );
              final fontSize = constraints.maxWidth < 360 ? 17.0 : 19.0;
              final scaledFontSize = textScaler.scale(fontSize);
              final iconSize = scaledFontSize * 2.25;
              final bottleIconSize = iconSize * 0.72;
              final featherIconSize = iconSize * 1.1;
              final topPadding = constraints.maxHeight < 700 ? 16.0 : 36.0;
              const bottomPadding = 12.0;
              final sectionSpacing = constraints.maxHeight < 700 ? 20.0 : 32.0;
              final actionRowsHeight =
                  math.max(48.0, bottleIconSize) +
                  math.max(48.0, featherIconSize);
              final subtitlesHeight = scaledFontSize * 1.3 * 2;
              final fixedContentHeight =
                  topPadding +
                  bottomPadding +
                  sectionSpacing +
                  actionRowsHeight +
                  subtitlesHeight +
                  36;
              final fittedExampleHeight = math.min(
                exampleHeight,
                math.max(
                  120.0,
                  (constraints.maxHeight - fixedContentHeight) / 2,
                ),
              );
              final textStyle = GoogleFonts.arvo(
                color: HonooColor.onBackground,
                fontSize: fontSize,
                height: 1.3,
              );

              return Stack(
                children: [
                  Positioned.fill(
                    child: SingleChildScrollView(
                      key: const Key('composer_onboarding_scroll'),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        topPadding,
                        horizontalPadding,
                        bottomPadding,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Column(
                            children: [
                              _InlineComposerAction(
                                actionKey: const Key(
                                  'composer_onboarding_bottle',
                                ),
                                textStyle: textStyle,
                                iconAsset: 'assets/icons/bottle.svg',
                                iconSemanticsLabel: 'Bottiglia',
                                tooltip: 'Componi il tuo honoo',
                                onPressed: () => _openHonooComposer(context),
                                iconSize: bottleIconSize,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'per comporre il tuo honoo',
                                style: textStyle,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 14),
                              _ExampleImage(
                                asset: 'assets/images/onboarding_honoo.png',
                                width: imageWidth,
                                height: fittedExampleHeight,
                                semanticsLabel: 'Esempio di honoo',
                              ),
                              SizedBox(height: sectionSpacing),
                              _InlineComposerAction(
                                actionKey: const Key(
                                  'composer_onboarding_feather',
                                ),
                                textStyle: textStyle,
                                iconAsset: 'assets/icons/piuma.svg',
                                iconSemanticsLabel: 'Piuma',
                                tooltip: 'Componi il tuo hinoo',
                                onPressed: () => _openHinooComposer(context),
                                iconSize: featherIconSize,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'per comporre il tuo hinoo',
                                style: textStyle,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 14),
                              _ExampleImage(
                                asset: 'assets/images/onboarding_hinoo.png',
                                width: imageWidth,
                                height: fittedExampleHeight,
                                semanticsLabel: 'Esempio di hinoo',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Semantics(
                      button: true,
                      label: 'Chiudi',
                      child: IconButton(
                        key: const Key('composer_onboarding_close'),
                        tooltip: 'Chiudi',
                        onPressed: () => _dismiss(context),
                        iconSize: 36,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        icon: SvgPicture.asset(
                          'assets/icons/cancella.svg',
                          width: 36,
                          height: 36,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _InlineComposerAction extends StatelessWidget {
  const _InlineComposerAction({
    required this.actionKey,
    required this.textStyle,
    required this.iconAsset,
    required this.iconSemanticsLabel,
    required this.tooltip,
    required this.onPressed,
    required this.iconSize,
  });

  final Key actionKey;
  final TextStyle textStyle;
  final String iconAsset;
  final String iconSemanticsLabel;
  final String tooltip;
  final VoidCallback onPressed;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Scegli', style: textStyle),
        const SizedBox(width: 9),
        IconButton(
          key: actionKey,
          tooltip: tooltip,
          onPressed: onPressed,
          iconSize: iconSize,
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: SvgPicture.asset(
            iconAsset,
            width: iconSize,
            height: iconSize,
            semanticsLabel: iconSemanticsLabel,
          ),
        ),
      ],
    );
  }
}

class _ExampleImage extends StatelessWidget {
  const _ExampleImage({
    required this.asset,
    required this.width,
    required this.height,
    required this.semanticsLabel,
  });

  final String asset;
  final double width;
  final double height;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticsLabel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          asset,
          width: width,
          height: height,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}
