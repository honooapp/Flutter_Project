import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../Utility/honoo_colors.dart';
import '../honoo_app_title.dart';

class ChingScaffold extends StatelessWidget {
  const ChingScaffold({
    super.key,
    required this.body,
  });

  final Widget body;

  static const String _honooLogo = 'assets/icons/honoo_logo.svg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER: back a sinistra, logo al centro
            SizedBox(
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 6,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back),
                      color: HonooColor.background,
                      splashRadius: 22,
                    ),
                  ),
                  const Center(
                    child: HonooAppTitle(),
                  ),
                ],
              ),
            ),

            // BODY (scrollabile, ma con larghezza limitata)
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: body,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
