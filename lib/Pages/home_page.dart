import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Services/supabase_provider.dart';
import 'package:honoo/Services/home_service.dart';
import 'package:honoo/Utility/app_logger.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import '../Widgets/honoo_app_title.dart';
import 'placeholder_page.dart';

// Widgets riutilizzabili
import '../Widgets/sea_footer_bar.dart';
import '../Widgets/luna_fissa.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _replyCount = 0;
  Timer? _replyRefreshTimer;
  bool _visitRecorded = false;
  final HomeService _homeService = const HomeService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReplyCount();
      _recordVisit();
    });
    _replyRefreshTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _loadReplyCount(),
    );
  }

  @override
  void dispose() {
    _replyRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadReplyCount() async {
    final user = SupabaseProvider.client.auth.currentUser;
    if (user == null) return;
    try {
      final count = await _homeService.fetchUnreadReplyCount(user.id);
      if (!mounted) return;
      if (count != _replyCount) {
        setState(() => _replyCount = count);
      }
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Impossibile aggiornare il contatore risposte',
        scope: 'HomePage',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _recordVisit() async {
    if (_visitRecorded) return;
    _visitRecorded = true;
    try {
      await _homeService.recordVisit();
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Impossibile registrare la visita',
        scope: 'HomePage',
        error: error,
        stackTrace: stackTrace,
      );
      _visitRecorded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('home_screen_root'),
      backgroundColor: HonooColor.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double maxWidth = constraints.maxWidth;
          final bool isPhone = maxWidth < 600;
          final double contentWidth = isPhone ? maxWidth : maxWidth * 0.5;

          return Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              // CONTENUTO PRINCIPALE
              Column(
                children: [
                  SizedBox(
                    height: 52,
                    child: HonooAppTitle(
                      onTap: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const PlaceholderPage(),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentWidth),
                        child: const Padding(
                          padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: _HomeIntro(),
                        ),
                      ),
                    ),
                  ),

                  // FOOTER sostituito col widget riutilizzabile
                  SeaFooterBar(replyCount: _replyCount),
                ],
              ),

              // 🌙 LUNA FISSA (riutilizzabile ovunque)
              const LunaFissa(showAdminEntry: true),
            ],
          );
        },
      ),
    );
  }
}

class _HomeIntro extends StatelessWidget {
  const _HomeIntro();

  static const double _designWidth = 360;
  static const double _moonIconSize = 22;
  static const double _largeIconSize = 26;

  @override
  Widget build(BuildContext context) {
    final regularStyle = GoogleFonts.arvo(
      color: HonooColor.onBackground,
      fontSize: 18,
      height: 1.22,
      fontWeight: FontWeight.w400,
    );

    return FittedBox(
      key: const Key('home_intro_fitted'),
      fit: BoxFit.scaleDown,
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: _designWidth,
        child: Text.rich(
          TextSpan(
            style: regularStyle,
            children: [
              TextSpan(
                text: 'Ti regaliamo la Luna\nPer sempre\n\n',
                style: regularStyle.copyWith(fontWeight: FontWeight.w700),
              ),
              const TextSpan(
                text:
                    'Niente è per sempre\n'
                    'E nessuno può regalarti la Luna\n\n'
                    'È vero\n'
                    'Ma non per i poeti\n\n'
                    'Vuoi essere un poeta di honoo?\n\n'
                    'Clicca su ',
              ),
              _inlineAction(
                key: const Key('home_inline_bottle'),
                asset: 'assets/icons/bottle.svg',
                size: _largeIconSize,
                tooltip: 'Scrivi',
                onPressed: () => SeaFooterBar.openComposer(context),
              ),
              const TextSpan(text: '\n\nOppure su '),
              _inlineAction(
                key: const Key('home_inline_moon'),
                asset: 'assets/icons/moon.svg',
                size: _moonIconSize,
                tooltip: 'Vai sulla Luna',
                onPressed: () => LunaFissa.openMoon(context),
              ),
              const TextSpan(text: '\ne guarda le vite degli altri\n\nO su '),
              _inlineAction(
                key: const Key('home_inline_island'),
                asset: 'assets/icons/isoladellestorie/island.svg',
                size: _largeIconSize,
                tooltip: "Vai all'Isola delle Storie",
                onPressed: () => SeaFooterBar.openIsland(context),
                tint: HonooColor.onBackground,
              ),
              const TextSpan(
                text: '\ne inizia il viaggio\nverso le tue storie',
              ),
            ],
          ),
          key: const Key('home_intro_text'),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  static WidgetSpan _inlineAction({
    required Key key,
    required String asset,
    required double size,
    required String tooltip,
    required VoidCallback onPressed,
    Color? tint,
  }) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: IconButton(
        key: key,
        constraints: BoxConstraints.tightFor(width: size, height: size),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        tooltip: tooltip,
        onPressed: onPressed,
        icon: SvgPicture.asset(
          asset,
          width: size,
          height: size,
          colorFilter: tint == null
              ? null
              : ColorFilter.mode(tint, BlendMode.srcIn),
        ),
      ),
    );
  }
}
