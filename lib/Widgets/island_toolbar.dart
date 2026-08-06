import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../Pages/chest_page.dart';
import '../Pages/home_page.dart';
import '../Utility/honoo_colors.dart';
import 'composer_onboarding.dart';

class IslandToolbar extends StatelessWidget {
  const IslandToolbar({super.key, required this.onInfo});

  final VoidCallback onInfo;

  static const double height = 80;
  static const double _bottleSize = 70;
  static const double _chestSize = 70;
  static const double _homeSize = 40;
  static const double _infoSize = 70;
  static const double _iconButtonPadding = 16;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;

        double clampX(double x, double size) =>
            x.clamp(0.0, width - size).toDouble();

        final double bottleX = clampX(
          (width / 2) + 60,
          _bottleSize + _iconButtonPadding,
        );
        final double chestX = clampX(
          (width / 2) - (_chestSize / 2),
          _chestSize + _iconButtonPadding,
        );
        final double homeX = clampX(
          (width / 2) - 190,
          _homeSize + _iconButtonPadding,
        );
        final double infoX = clampX(
          (width / 2) + 110,
          _infoSize + _iconButtonPadding,
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Container(height: 10, color: HonooColor.wave1),
            ),
            Positioned(
              key: const Key('island_footer_bottle'),
              bottom: 27,
              left: bottleX,
              child: IconButton(
                icon: SvgPicture.asset(
                  'assets/icons/bottle.svg',
                  semanticsLabel: 'Bottle',
                ),
                iconSize: _bottleSize,
                splashRadius: 40,
                tooltip: 'Scrivi',
                onPressed: () => ComposerLauncher.open(context),
              ),
            ),
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(height: 20, color: HonooColor.wave2),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(height: 30, color: HonooColor.wave3),
              ),
            ),
            Positioned(
              bottom: 0,
              left: homeX,
              child: IconButton(
                icon: SvgPicture.asset(
                  'assets/icons/home.svg',
                  colorFilter: const ColorFilter.mode(
                    HonooColor.onBackground,
                    BlendMode.srcIn,
                  ),
                  width: _homeSize,
                  height: _homeSize,
                  semanticsLabel: 'Home',
                ),
                iconSize: _homeSize,
                splashRadius: 1,
                tooltip: 'Home',
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomePage()),
                    (route) => false,
                  );
                },
              ),
            ),
            Positioned(
              key: const Key('island_footer_chest'),
              bottom: -7,
              left: chestX,
              child: IconButton(
                icon: SvgPicture.asset(
                  'assets/icons/chest.svg',
                  semanticsLabel: 'Chest',
                ),
                iconSize: _chestSize,
                splashRadius: 40,
                tooltip: 'Apri il tuo Cuore',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChestPage()),
                  );
                },
              ),
            ),
            Positioned(
              key: const Key('island_footer_info'),
              bottom: -5,
              left: infoX,
              child: IconButton(
                icon: SvgPicture.asset(
                  'assets/icons/info.svg',
                  semanticsLabel: 'Info',
                ),
                iconSize: _infoSize,
                splashRadius: 30,
                tooltip: 'Info',
                onPressed: onInfo,
              ),
            ),
          ],
        );
      },
    ),
  );
}
