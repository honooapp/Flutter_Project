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
              final iconSize = (constraints.maxWidth * 0.15).clamp(48.0, 72.0);
              final bottleIconSize = (iconSize * 0.65).clamp(32.0, 44.0);
              final textStyle = GoogleFonts.arvo(
                color: HonooColor.onBackground,
                fontSize: constraints.maxWidth < 360 ? 17 : 19,
                height: 1.3,
              );

              return Stack(
                children: [
                  Positioned.fill(
                    child: SingleChildScrollView(
                      key: const Key('composer_onboarding_scroll'),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        72,
                        horizontalPadding,
                        32,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Column(
                            children: [
                              Text(
                                'Clicca qui',
                                style: textStyle,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              IconButton(
                                key: const Key('composer_onboarding_bottle'),
                                tooltip: 'Componi il tuo honoo',
                                onPressed: () => _openHonooComposer(context),
                                iconSize: bottleIconSize,
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
                                icon: SvgPicture.asset(
                                  'assets/icons/bottle.svg',
                                  width: bottleIconSize,
                                  height: bottleIconSize,
                                  semanticsLabel: 'Bottiglia',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'per comporre il tuo honoo',
                                style: textStyle,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 14),
                              _ExampleImage(
                                asset: 'assets/images/onboarding_honoo.png',
                                width: imageWidth,
                                height: exampleHeight,
                                semanticsLabel: 'Esempio di honoo',
                              ),
                              const SizedBox(height: 56),
                              Text(
                                'Clicca qui',
                                style: textStyle,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              IconButton(
                                key: const Key('composer_onboarding_feather'),
                                tooltip: 'Componi il tuo hinoo',
                                onPressed: () => _openHinooComposer(context),
                                iconSize: iconSize,
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints.tightFor(
                                  width: iconSize,
                                  height: iconSize,
                                ),
                                icon: SvgPicture.asset(
                                  'assets/icons/piuma.svg',
                                  width: iconSize,
                                  height: iconSize,
                                  semanticsLabel: 'Piuma',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'per comporre il tuo hinoo',
                                style: textStyle,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 14),
                              _ExampleImage(
                                asset: 'assets/images/onboarding_hinoo.png',
                                width: imageWidth,
                                height: exampleHeight,
                                semanticsLabel: 'Esempio di hinoo',
                              ),
                              const SizedBox(height: 32),
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
