import 'package:flutter/material.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Services/house_invite_service.dart';
import 'package:honoo/Services/supabase_provider.dart';
import 'package:honoo/Widgets/honoo_dialogs.dart';
import '../Utility/utility.dart';
import '../Widgets/honoo_app_title.dart';
import 'placeholder_page.dart';
import 'new_hinoo_page.dart';

// Widgets riutilizzabili
import '../Widgets/sea_footer_bar.dart';
import '../Widgets/luna_fissa.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HouseInviteService _inviteService = HouseInviteService();
  bool _inviteFlowChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkInviteFlow());
  }

  Future<void> _checkInviteFlow() async {
    if (_inviteFlowChecked) return;
    _inviteFlowChecked = true;

    final user = SupabaseProvider.client.auth.currentUser;
    if (user == null) return;

    final hasCasa = await _inviteService.hasCasa(user.id);
    if (hasCasa) return;

    final hasInvite =
        await _inviteService.hasPendingOrAcceptedInvite(user.id);
    if (!hasInvite || !mounted) return;

    await _showCasaInviteDialog();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NewHinooPage(isCampanello: true),
      ),
    );
  }

  Future<void> _showCasaInviteDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => HonooDialogShell(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Complimenti!',
                style: HonooDialogStyles.title(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Ecco la tua casa sull\'Isola, crea il tuo campanello!',
                style: HonooDialogStyles.body(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Crea il campanello',
                    style: HonooDialogStyles.primaryAction(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HonooColor.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double maxWidth = constraints.maxWidth;
          final double maxHeight = constraints.maxHeight;
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
                  Expanded(
                    child: SingleChildScrollView(
                      child: SizedBox(
                        width: maxWidth,
                        child: Row(
                          children: [
                            Expanded(child: Container()),
                            Container(
                              constraints:
                                  BoxConstraints(maxWidth: contentWidth),
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: maxHeight * 0.8,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Positioned.fill(
                                          top: 0,
                                          child: Align(
                                            alignment: Alignment.topCenter,
                                            child: SingleChildScrollView(
                                              child: Column(
                                                children: [
                                                  const SizedBox(height: 32),
                                                  Text(
                                                    Utility().textHome1,
                                                    style: GoogleFonts.arvo(
                                                      color: HonooColor
                                                          .onBackground,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 24),
                                                  Text(
                                                    Utility().textHome2,
                                                    style: GoogleFonts.arvo(
                                                      color: HonooColor
                                                          .onBackground,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(child: Container()),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // FOOTER sostituito col widget riutilizzabile
                  const SeaFooterBar(),
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
