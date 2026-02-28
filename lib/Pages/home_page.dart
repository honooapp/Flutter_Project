import 'dart:async';

import 'package:flutter/material.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honoo/Services/supabase_provider.dart';
import 'package:honoo/Utility/replies_seen_tracker.dart';
import '../Utility/utility.dart';
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
      final lastSeen = await RepliesSeenTracker.lastSeen();
      final honooRows = await SupabaseProvider.client
          .from('honoo')
          .select('created_at')
          .eq('destination', 'reply')
          .eq('recipient_tag', user.id);
      final hinooRows = await SupabaseProvider.client
          .from('hinoo')
          .select('created_at')
          .eq('type', 'answer')
          .eq('recipient_tag', user.id);
      int count = 0;
      for (final r in (honooRows as List)) {
        final dt = DateTime.tryParse((r['created_at'] ?? '').toString());
        if (dt != null && (lastSeen == null || dt.isAfter(lastSeen))) count++;
      }
      for (final r in (hinooRows as List)) {
        final dt = DateTime.tryParse((r['created_at'] ?? '').toString());
        if (dt != null && (lastSeen == null || dt.isAfter(lastSeen))) count++;
      }
      if (!mounted) return;
      if (count != _replyCount) {
        setState(() => _replyCount = count);
      }
    } catch (_) {}
  }

  Future<void> _recordVisit() async {
    if (_visitRecorded) return;
    _visitRecorded = true;
    try {
      await SupabaseProvider.client.rpc('increment_site_visit');
    } catch (_) {
      _visitRecorded = false;
    }
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
