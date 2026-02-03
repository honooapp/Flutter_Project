import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:honoo/Pages/admin_menu_page.dart';
import 'package:honoo/Pages/email_login_page.dart';
import 'package:honoo/Pages/moon_page.dart';
import 'package:honoo/Services/admin_service.dart';
import 'package:honoo/Services/supabase_provider.dart';

class LunaFissa extends StatefulWidget {
  const LunaFissa({super.key, this.showAdminEntry = false});

  final bool showAdminEntry;

  /// Margine standard attorno alla luna
  static const double _margin = 8.0;
  static const double _largeDesktopMargin = 16.0;

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
  State<LunaFissa> createState() => _LunaFissaState();
}

class _LunaFissaState extends State<LunaFissa>
    with WidgetsBindingObserver {
  final AdminService _adminService = AdminService();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.showAdminEntry) {
      _loadAdminStatus();
    }
  }

  @override
  void didUpdateWidget(covariant LunaFissa oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.showAdminEntry && widget.showAdminEntry) {
      _loadAdminStatus();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.showAdminEntry) {
      _loadAdminStatus();
    }
  }

  Future<void> _loadAdminStatus() async {
    final user = SupabaseProvider.client.auth.currentUser;
    final isAdmin = await _adminService.isCurrentUserAdmin();
    debugPrint('[LunaFissa] uid=${user?.id} admin=$isAdmin');
    if (!mounted) return;
    setState(() => _isAdmin = isAdmin);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final topSafe = MediaQuery.of(context).viewPadding.top;
    final iconSize = LunaFissa.iconSizeForWidth(w);
    final double margin =
        w >= 1200 ? LunaFissa._largeDesktopMargin : LunaFissa._margin;

    final List<Widget> actions = [
      IconButton(
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
    ];

    if (widget.showAdminEntry && _isAdmin) {
      actions.add(SizedBox(height: iconSize * 0.35));
      actions.add(
        IconButton(
          icon: Image.asset(
            'assets/icons/venceslao.png',
            width: iconSize,
            height: iconSize,
          ),
          iconSize: iconSize,
          splashRadius: (iconSize / 2) + 6,
          tooltip: 'Admin',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminMenuPage(),
              ),
            );
          },
        ),
      );
    }

    return Positioned(
      // entro i limiti visivi: safe-area top + margine
      top: topSafe + margin,
      right: margin,
      child: IgnorePointer(
        // il bottone deve essere cliccabile, ma non deve bloccare altre aree:
        // usiamo un Material "shrink-wrapped" e riabilitiamo i pointer solo sul bottone
        ignoring: false,
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: actions,
          ),
        ),
      ),
    );
  }
}
