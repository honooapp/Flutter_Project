import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:honoo/Pages/email_login_page.dart';
import 'package:honoo/Pages/moon_page.dart';
import 'package:honoo/Services/supabase_provider.dart';

class LunaFissa extends StatelessWidget {
  const LunaFissa({super.key});

  /// Margine standard attorno alla luna
  static const double _margin = 8.0;

  /// Dimensione icona in base alla larghezza schermo (phone/tablet/web)
  static double iconSizeForWidth(double w) {
    if (w < 400) return 44;
    if (w < 700) return 52;
    if (w < 1200) return 60;
    return 68;
  }

  /// Padding verticale di riserva da applicare al contenuto
  /// per evitare qualunque sovrapposizione nel bordo alto.
  /// (top safe-area + dimensione icona + margini)
  static double reserveTopPadding(BuildContext context) {
    final vw = MediaQuery.of(context).size.width;
    final safeTop = MediaQuery.of(context).viewPadding.top;
    final icon = iconSizeForWidth(vw);
    return safeTop + icon + (_margin * 2);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final topSafe = MediaQuery.of(context).viewPadding.top;
    final iconSize = iconSizeForWidth(w);

    return Positioned(
      // entro i limiti visivi: safe-area top + margine
      top: topSafe + _margin,
      right: _margin,
      child: IgnorePointer(
        // il bottone deve essere cliccabile, ma non deve bloccare altre aree:
        // usiamo un Material "shrink-wrapped" e riabilitiamo i pointer solo sul bottone
        ignoring: false,
        child: Material(
          color: Colors.transparent,
          child: IconButton(
            icon: SvgPicture.asset(
              "assets/icons/moon.svg",
              semanticsLabel: 'Moon',
            ),
            iconSize: iconSize,
            splashRadius: (iconSize / 2) + 6,
            tooltip: 'Vai sulla Luna',
            onPressed: () {
              final user = SupabaseProvider.client.auth.currentUser;
              if (user == null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EmailLoginPage(),
                  ),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MoonPage(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
