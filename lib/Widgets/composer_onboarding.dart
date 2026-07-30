import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Pages/new_honoo_page.dart';
import '../Services/composer_onboarding_service.dart';
import '../Utility/honoo_colors.dart';

class ComposerLauncher {
  const ComposerLauncher._();

  static Future<void> open(
    BuildContext context, {
    ComposerOnboardingService? service,
  }) async {
    final onboardingService = service ?? ComposerOnboardingService();
    final shouldShow = await onboardingService.shouldShow();
    if (!context.mounted) return;

    if (shouldShow) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => ComposerOnboardingPage(service: onboardingService),
        ),
      );
      return;
    }

    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => const NewHonooPage()));
  }
}

class ComposerOnboardingPage extends StatelessWidget {
  const ComposerOnboardingPage({required this.service, super.key});

  final ComposerOnboardingService service;

  Future<void> _dismiss(BuildContext context) async {
    await service.dismissPermanently();
    if (context.mounted) Navigator.of(context).pop();
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
                              SvgPicture.asset(
                                'assets/icons/bottle.svg',
                                key: const Key('composer_onboarding_bottle'),
                                width: iconSize,
                                height: iconSize,
                                semanticsLabel: 'Bottiglia',
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
                              const SizedBox(height: 28),
                              Text(
                                'Clicca qui',
                                style: textStyle,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              SvgPicture.asset(
                                'assets/icons/piuma.svg',
                                key: const Key('composer_onboarding_feather'),
                                width: iconSize,
                                height: iconSize,
                                semanticsLabel: 'Piuma',
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
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Text('Se clicchi', style: textStyle),
                                  SvgPicture.asset(
                                    'assets/icons/cancella.svg',
                                    key: const Key(
                                      'composer_onboarding_inline_close',
                                    ),
                                    width: 42,
                                    height: 42,
                                    semanticsLabel: 'Cancella',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'non vedrai più questa schermata.',
                                style: textStyle,
                                textAlign: TextAlign.center,
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
                      label: 'Chiudi e non mostrare più',
                      child: IconButton(
                        key: const Key('composer_onboarding_close'),
                        tooltip: 'Chiudi e non mostrare più',
                        onPressed: () => _dismiss(context),
                        iconSize: 52,
                        padding: const EdgeInsets.all(8),
                        icon: SvgPicture.asset(
                          'assets/icons/cancella.svg',
                          width: 52,
                          height: 52,
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
