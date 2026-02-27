import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:honoo/Entities/hinoo.dart';
import 'package:honoo/Entities/honoo.dart';
import 'package:honoo/Services/supabase_provider.dart';
import 'package:honoo/UI/hinoo_viewer.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Utility/responsive_layout.dart';
import 'package:honoo/Widgets/honoo_app_title.dart';
import 'package:honoo/UI/thread_layout_scaffold.dart';
import 'package:honoo/Widgets/loading_spinner.dart';
import 'package:honoo/Widgets/responsive_footer_bar.dart';
import 'package:honoo/Widgets/desktop_carousel_arrows.dart';
import 'package:honoo/Widgets/honoo_dialogs.dart';
import 'new_hinoo_page.dart';
import 'new_honoo_page.dart';

import 'home_page.dart';
import 'chest_page.dart';
import 'placeholder_page.dart';

class SharedHinooPage extends StatefulWidget {
  const SharedHinooPage({super.key, required this.ownerId});

  final String ownerId;

  @override
  State<SharedHinooPage> createState() => _SharedHinooPageState();
}

class _SharedHinooPageState extends State<SharedHinooPage> {
  List<_SharedHinooItem> _items = const [];
  bool _isLoading = true;
  int _currentIndex = 0;
  final cs.CarouselController _carouselController = cs.CarouselController();
  bool _replying = false;

  @override
  void initState() {
    super.initState();
    _loadHinoo();
  }

  Future<void> _loadHinoo() async {
    setState(() => _isLoading = true);
    try {
      final rows = await SupabaseProvider.client
          .from('hinoo')
          .select('id,pages,type,recipient_tag,created_at')
          .eq('user_id', widget.ownerId)
          .eq('type', 'personal')
          .order('created_at', ascending: false);

      final list = <_SharedHinooItem>[];
      for (final row in (rows as List)) {
        final pages = row['pages'];
        if (pages is! List) continue;
        final draft = HinooDraft(
            pages: pages
                .whereType<Map<String, dynamic>>()
                .map((entry) => HinooSlide.fromJson(entry))
                .toList(),
            type: HinooType.personal,
            recipientTag: row['recipient_tag'] as String?,
          );
        final String id = row['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        list.add(_SharedHinooItem(id: id, draft: draft));
      }

      if (!mounted) return;
      setState(() {
        _items = list;
        _currentIndex = _items.isEmpty ? 0 : _currentIndex.clamp(0, _items.length - 1);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ThreadLayoutScaffold(
      backgroundColor: HonooColor.background,
      header: HonooAppTitle(
        onTap: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const PlaceholderPage()),
            (route) => false,
          );
        },
      ),
      bodyBuilder: (context, viewW, availableH, layoutMode) {
        final Widget content = _isLoading
            ? const Center(child: LoadingSpinner())
            : (_items.isEmpty
                ? Center(
                    child: Text(
                      'Nessun hinoo condiviso',
                      style: GoogleFonts.libreFranklin(
                        color: HonooColor.onBackground,
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  )
                : cs.CarouselSlider(
                    carouselController: _carouselController,
                    options: cs.CarouselOptions(
                      scrollDirection: Axis.horizontal,
                      height: availableH,
                      viewportFraction: 1.0,
                      enlargeCenterPage: false,
                      enableInfiniteScroll: false,
                      disableCenter: true,
                      scrollPhysics: (layoutMode == ResponsiveLayoutMode.mobile ||
                              layoutMode == ResponsiveLayoutMode.tablet)
                          ? const BouncingScrollPhysics()
                          : const PageScrollPhysics(),
                      onPageChanged: (index, reason) {
                        setState(() => _currentIndex = index);
                      },
                    ),
                    items: _items
                        .map(
                          (item) => SizedBox(
                            width: viewW,
                            height: availableH,
                            child: HinooViewer(
                              draft: item.draft,
                              maxHeight: availableH,
                              maxWidth: viewW,
                            ),
                          ),
                        )
                        .toList(),
                  ));

        final bool isDesktop = layoutMode == ResponsiveLayoutMode.desktop ||
            layoutMode == ResponsiveLayoutMode.wideDesktop ||
            layoutMode == ResponsiveLayoutMode.largeDesktop;
        if (!isDesktop || _items.length <= 1 || _isLoading) {
          return content;
        }
        final Widget base = DesktopCarouselArrows(
          canPrev: _currentIndex > 0,
          canNext: _currentIndex < _items.length - 1,
          onPrev: () => _carouselController.animateToPage(
            (_currentIndex - 1).clamp(0, _items.length - 1),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          ),
          onNext: () => _carouselController.animateToPage(
            (_currentIndex + 1).clamp(0, _items.length - 1),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          ),
          arrowColor: Colors.white,
          child: content,
        );
        return Actions(
          actions: <Type, Action<Intent>>{
            _ArrowIntent: CallbackAction<_ArrowIntent>(
              onInvoke: (intent) {
                if (!isDesktop) return null;
                final int target = (_currentIndex + intent.delta)
                    .clamp(0, (_items.length - 1));
                if (target == _currentIndex) return null;
                _carouselController.animateToPage(
                  target,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                );
                return null;
              },
            ),
          },
          child: Shortcuts(
            shortcuts: <LogicalKeySet, Intent>{
              LogicalKeySet(LogicalKeyboardKey.arrowLeft): const _ArrowIntent(-1),
              LogicalKeySet(LogicalKeyboardKey.arrowRight): const _ArrowIntent(1),
            },
            child: Focus(
              autofocus: true,
              child: base,
            ),
          ),
        );
      },
      footerBuilder: (context, layoutMode, footerIconSize, footerGap,
          footerTopSpacing, footerBottomSpacing) {
        return ResponsiveFooterBar(
          useSafeArea: false,
          bottomPadding: footerBottomSpacing,
          desiredGap: footerGap,
          minGap: 16,
          height: footerIconSize,
          actions: [
            ResponsiveFooterAction(
              asset: "assets/icons/home.svg",
              semanticsLabel: 'Home',
              colorFilter: const ColorFilter.mode(
                HonooColor.onBackground,
                BlendMode.srcIn,
              ),
              size: footerIconSize,
              splashRadius: 25,
              tooltip: 'Home',
              onPressed: _goHome,
            ),
            if (!_isLoading && _items.isNotEmpty && !_replying)
              ResponsiveFooterAction(
                asset: 'assets/icons/reply.svg',
                semanticsLabel: 'Rispondi',
                size: footerIconSize,
                splashRadius: 25,
                tooltip: 'Rispondi',
                onPressed: () async {
                setState(() => _replying = true);
                  final ctx = context;
                  final nav = Navigator.of(ctx);
                  bool locked = false;
                  final _ReplyChoice? choice = await showDialog<_ReplyChoice>(
                    context: ctx,
                    barrierDismissible: true,
                    builder: (_) => HonooDialogShell(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                            Text(
                              'Vuoi rispondere con\n un honoo o un hinoo?',
                              style: HonooDialogStyles.title(),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'La risposta verrà mostrata nelle conversazioni dello Scrigno.',
                              style: HonooDialogStyles.tertiaryAction(),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (locked) return;
                                  locked = true;
                                  Navigator.of(ctx).pop(_ReplyChoice.honoo);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'honoo',
                                  style: HonooDialogStyles.primaryAction(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (locked) return;
                                  locked = true;
                                  Navigator.of(ctx).pop(_ReplyChoice.hinoo);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'hinoo',
                                  style: HonooDialogStyles.primaryAction(),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: locked
                                  ? null
                                  : () {
                                      if (locked) return;
                                      locked = true;
                                      Navigator.of(ctx).pop();
                                    },
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.white54),
                              child: Text(
                                'Annulla',
                                style: HonooDialogStyles.tertiaryAction(),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ),
                  );
                  if (choice == null || !mounted) return;
                  final _SharedHinooItem current = _items[_currentIndex];
                  if (choice == _ReplyChoice.hinoo) {
                    // ignore: use_build_context_synchronously
                    showHonooToast(ctx, message: 'Risposta inviata.');
                    // ignore: use_build_context_synchronously
                    // ignore: use_build_context_synchronously
                    await showDialog<void>(
                      // ignore: use_build_context_synchronously
                      context: ctx,
                      barrierDismissible: false,
                      builder: (_) => const HonooDialogShell(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: 8),
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Apro la conversazione...',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                        ),
                      ),
                    ),
                  );
                    // ignore: use_build_context_synchronously
                    await nav.push(
                      MaterialPageRoute(
                        builder: (_) => NewHinooPage(
                          forcedType: HinooType.answer,
                          recipientTag: widget.ownerId,
                          replyTo: current.id,
                        ),
                      ),
                    );
                    if (!mounted) return;
                    // ignore: use_build_context_synchronously
                    await nav.push(
                      MaterialPageRoute(
                        builder: (_) => const ChestPage(focusReplies: true),
                      ),
                    );
                    if (mounted) {
                      // ignore: use_build_context_synchronously
                      final rootNav = Navigator.of(ctx, rootNavigator: true);
                      rootNav.maybePop();
                    }
                  } else {
                    // Risposta con honoo indirizzata al proprietario
                    // ignore: use_build_context_synchronously
                    showHonooToast(ctx, message: 'Risposta inviata.');
                    // ignore: use_build_context_synchronously
                    // ignore: use_build_context_synchronously
                    await showDialog<void>(
                      // ignore: use_build_context_synchronously
                      context: ctx,
                      barrierDismissible: false,
                      builder: (_) => const HonooDialogShell(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: 8),
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Apro la conversazione...',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                    // ignore: use_build_context_synchronously
                    await nav.push(
                      MaterialPageRoute(
                        builder: (_) => NewHonooPage(
                          forcedType: HonooType.answer,
                          recipientTag: widget.ownerId,
                          returnSavedId: false,
                        ),
                      ),
                    );
                    if (!mounted) return;
                    // ignore: use_build_context_synchronously
                    await nav.push(
                      MaterialPageRoute(
                        builder: (_) => const ChestPage(focusReplies: true),
                      ),
                    );
                    if (mounted) {
                      // ignore: use_build_context_synchronously
                      final rootNav = Navigator.of(ctx, rootNavigator: true);
                      rootNav.maybePop();
                    }
                  }
                  if (mounted) setState(() => _replying = false);
                },
              ),
            if (!_isLoading && _items.isNotEmpty && _replying)
              ResponsiveFooterAction(
                asset: 'assets/icons/reply.svg',
                semanticsLabel: 'Rispondi',
                size: footerIconSize,
                splashRadius: 25,
                tooltip: 'Rispondi',
                onPressed: null,
                icon: SizedBox(width: footerIconSize, height: footerIconSize),
              ),
          ],
        );
      },
    );
  }
}

class _ArrowIntent extends Intent {
  const _ArrowIntent(this.delta);
  final int delta;
}

class _SharedHinooItem {
  final String id;
  final HinooDraft draft;

  const _SharedHinooItem({required this.id, required this.draft});
}

enum _ReplyChoice { honoo, hinoo }
