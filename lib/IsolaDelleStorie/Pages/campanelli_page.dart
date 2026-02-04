import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:honoo/Entities/hinoo.dart';
import 'package:honoo/Services/supabase_provider.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Utility/responsive_layout.dart';
import 'package:honoo/Utility/utility.dart';
import 'package:honoo/Widgets/honoo_dialogs.dart';
import 'package:honoo/Widgets/responsive_footer_bar.dart';
import 'package:honoo/UI/hinoo_typography.dart';

import '../../Pages/home_page.dart';
import '../../Pages/shared_conversations_page.dart';
import '../../Pages/shared_hinoo_page.dart';
import '../../Pages/shared_honoo_page.dart';

class CampanelliPage extends StatefulWidget {
  const CampanelliPage({super.key});

  @override
  State<CampanelliPage> createState() => _CampanelliPageState();
}

class _CampanelliPageState extends State<CampanelliPage> {
  int _campanelloIndex = 0;
  int _verticalPageIndex = 0;
  int _lastHouseCampanelloIndex = 1;
  final PageController _pageController = PageController();
  final PageController _campanelloPageController = PageController();
  List<_CampanelloEntry> _userEntries = const [];
  bool _isLoadingUserEntries = false;
  bool _isHoveringCampanelli = false;
  bool _checkedKnocks = false;
  final Set<String> _pendingKnockTags = {};
  final Map<String, _CasaShareMode> _shareModesByCampanello = {
    campanelloSirenaId: _CasaShareMode.honoo,
    campanelloPalombaroId: _CasaShareMode.hinoo,
  };

  static const String campanelloSirenaId = 'campanello_sirena';
  static const String campanelloPalombaroId = 'campanello_palombaro';
  static const String casaSirenaId = 'casa_sirena';
  static const String casaPalombaroId = 'casa_palombaro';
  static const String campanelloSirenaBg = 'assets/campanello1.png';
  static const String campanelloPalombaroBg = 'assets/campanello2.png';
  static const String casaSirenaBg = 'assets/images/casa_sirena.png';
  static const String casaPalombaroBg = 'assets/images/casa_palombaro.png';
  static const String defaultCasaBg = 'assets/images/casa_palombaro.png';
  static const String userCampanelloBg = 'assets/campanello1.png';
  static const String scrignoOverlay = 'assets/icons/scrigno_di_carta.png';
  final Set<String> _unlockedCampanelli = {
    campanelloSirenaId,
    campanelloPalombaroId,
  };

  @override
  void initState() {
    super.initState();
    _loadUserEntries();
  }

  bool _isCampanelloUnlocked(String id) => _unlockedCampanelli.contains(id);

  void _handlePointerScroll(
    PageController controller,
    PointerScrollEvent event,
    Axis axis,
  ) {
    if (!controller.hasClients || !controller.position.haveDimensions) {
      return;
    }
    final position = controller.position;
    if ((position.maxScrollExtent - position.minScrollExtent).abs() < 0.5) {
      return;
    }
    final double delta = axis == Axis.vertical
        ? event.scrollDelta.dy
        : (event.scrollDelta.dy.abs() > 0
            ? event.scrollDelta.dy
            : event.scrollDelta.dx);
    if (delta.abs() < 0.5) {
      return;
    }
    final double target = (position.pixels + delta)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((target - position.pixels).abs() > 0.5) {
      controller.jumpTo(target);
    }
  }

  void _animatePage(
    PageController controller, {
    required int delta,
    required int maxIndex,
  }) {
    if (!controller.hasClients) return;
    final double? page = controller.page;
    final int current = page?.round() ?? controller.initialPage;
    final int target = (current + delta).clamp(0, maxIndex);
    if (target == current) return;
    controller.animateToPage(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _handleKnock(CampanelloData campanello) async {
    if (_isCampanelloUnlocked(campanello.id)) {
      await _showEnterDialog(campanello.id);
      return;
    }

    final bool? shouldKnock = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const HonooConfirmDialog(
        title: 'Vuoi bussare al campanello?',
        confirmLabel: 'Bussa',
        cancelLabel: 'Non ora',
      ),
    );

    if (shouldKnock != true || !mounted) return;

    showHonooToast(context, message: 'Bussata inviata.');
    await _sendHouseKnock(campanello);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    await _showEnterDialog(campanello.id);
  }

  Future<void> _sendHouseKnock(CampanelloData campanello) async {
    final user = SupabaseProvider.client.auth.currentUser;
    final String? targetTag = campanello.campanelloHinooId;
    if (user == null || targetTag == null || targetTag.isEmpty) return;
    if (campanello.ownerId == user.id) return;

    try {
      await SupabaseProvider.client.from('house_access').insert({
        'target_house_tag': targetTag,
        'visitor_id': user.id,
      });
    } catch (_) {}
  }

  Future<void> _showEnterDialog(String campanelloId) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const HonooConfirmDialog(
        title: 'Entra pure a casa mia',
        confirmLabel: 'Entra',
        cancelLabel: 'Non ora',
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _unlockedCampanelli.add(campanelloId));
    await _hintSwipeUp();
  }

  Future<void> _hintSwipeUp() async {
    if (!_pageController.hasClients) return;
    final position = _pageController.position;
    final double bump = position.viewportDimension * 0.12;
    final double start = position.pixels;
    final double target = (start + bump)
        .clamp(position.minScrollExtent, position.maxScrollExtent);

    await _pageController.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
    await _pageController.animateTo(
      start,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  String _shareKeyFor(CampanelloData campanello) {
    return campanello.campanelloHinooId ?? campanello.id;
  }

  Future<void> _handleScrigno(CampanelloData campanello) async {
    if (!_isCampanelloUnlocked(campanello.id)) {
      showHonooToast(context, message: 'Casa chiusa.');
      return;
    }

    final String shareKey = _shareKeyFor(campanello);
    _CasaShareMode? mode = _shareModesByCampanello[shareKey];
    final user = SupabaseProvider.client.auth.currentUser;
    final bool isOwner = user != null && campanello.ownerId == user.id;

    if (mode == null && isOwner) {
      final selected = await _showShareModeDialog();
      if (selected == null || !mounted) return;
      await _saveShareMode(campanello, selected);
      if (!mounted) return;
      mode = selected;
    }

    if (!mounted) return;
    if (mode == null) {
      showHonooToast(
        context,
        message: 'Il padrone di casa non ha ancora scelto cosa condividere.',
      );
      return;
    }

    _openSharedContent(mode, campanello);
  }

  Future<_CasaShareMode?> _showShareModeDialog() {
    return showDialog<_CasaShareMode>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _CasaShareDialog(),
    );
  }

  Future<void> _saveShareMode(
    CampanelloData campanello,
    _CasaShareMode mode,
  ) async {
    final user = SupabaseProvider.client.auth.currentUser;
    final shareKey = _shareKeyFor(campanello);

    if (user == null || campanello.campanelloHinooId == null) {
      setState(() => _shareModesByCampanello[shareKey] = mode);
      return;
    }

    await SupabaseProvider.client.from('house_share_settings').upsert({
      'owner_id': user.id,
      'campanello_hinoo_id': campanello.campanelloHinooId,
      'share_mode': mode.dbValue,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'campanello_hinoo_id');

    if (!mounted) return;
    setState(() => _shareModesByCampanello[shareKey] = mode);
  }

  void _openSharedContent(_CasaShareMode mode, CampanelloData campanello) {
    final ownerId = campanello.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      showHonooMessageDialog(
        context,
        title: 'Questa è una casa di esempio',
        message: 'Il contenuto condiviso non è ancora disponibile.',
        duration: const Duration(milliseconds: 1600),
      );
      return;
    }

    switch (mode) {
      case _CasaShareMode.honoo:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SharedHonooPage(ownerId: ownerId),
          ),
        );
        return;
      case _CasaShareMode.hinoo:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SharedHinooPage(ownerId: ownerId),
          ),
        );
        return;
      case _CasaShareMode.conversations:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SharedConversationsPage(ownerId: ownerId),
          ),
        );
        return;
    }
  }

  List<_CampanelloEntry> _buildBaseCampanelli() {
    return [
      _CampanelloEntry(
        campanello: CampanelloData(
          id: campanelloSirenaId,
          campanelloHinooId: null,
          ownerId: null,
          backgroundImage: const AssetImage(campanelloSirenaBg),
          text: Utility().campanelloExample1Text,
          linkedHouseId: casaSirenaId,
        ),
        casa: const CasaData(
          id: casaSirenaId,
          backgroundImage: AssetImage(casaSirenaBg),
          bgScale: 1.0,
          bgOffsetX: 0.0,
          bgOffsetY: 0.0,
        ),
      ),
      _CampanelloEntry(
        campanello: CampanelloData(
          id: campanelloPalombaroId,
          campanelloHinooId: null,
          ownerId: null,
          backgroundImage: const AssetImage(campanelloPalombaroBg),
          text: Utility().campanelloExample2Text,
          linkedHouseId: casaPalombaroId,
        ),
        casa: const CasaData(
          id: casaPalombaroId,
          backgroundImage: AssetImage(casaPalombaroBg),
          bgScale: 1.0,
          bgOffsetX: 0.0,
          bgOffsetY: 0.0,
        ),
      ),
    ];
  }

  List<_CampanelloEntry> _buildCampanelli() {
    return [
      ..._buildBaseCampanelli(),
      ..._userEntries,
    ];
  }

  List<_CampanelloPageData> _buildCampanelloPages(
    List<_CampanelloEntry> campanelli,
  ) {
    return [
      _CampanelloPageData.intro(Utility().campanelliText),
      for (final campanello in campanelli)
        _CampanelloPageData.campanello(campanello.campanello),
    ];
  }

  ImageProvider _houseBackgroundProvider(String? backgroundUrl) {
    if (backgroundUrl != null && backgroundUrl.isNotEmpty) {
      return NetworkImage(backgroundUrl);
    }
    return const AssetImage(defaultCasaBg);
  }

  Future<void> _loadUserEntries() async {
    if (_isLoadingUserEntries) return;
    final user = SupabaseProvider.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoadingUserEntries = true);
    try {
      final rows = await SupabaseProvider.client
          .from('case')
          .select('campanello_hinoo_id')
          .eq('owner_id', user.id);

      final List<String> hinooIds = (rows as List)
          .map((row) => row is Map ? row['campanello_hinoo_id'] : null)
          .whereType<String>()
          .toList();

      if (hinooIds.isEmpty) {
        if (mounted) {
          setState(() => _userEntries = const []);
        }
        return;
      }

      final shareRows = await SupabaseProvider.client
          .from('house_share_settings')
          .select('campanello_hinoo_id,share_mode')
          .eq('owner_id', user.id)
          .in_('campanello_hinoo_id', hinooIds);

      for (final row in (shareRows as List)) {
        if (row is! Map) continue;
        final String? hinooId = row['campanello_hinoo_id'] as String?;
        final String? mode = row['share_mode'] as String?;
        final parsed = _CasaShareModeMapper.fromDb(mode);
        if (hinooId != null && parsed != null) {
          _shareModesByCampanello[hinooId] = parsed;
        }
      }

      final hinooRows = await SupabaseProvider.client
          .from('hinoo')
          .select('id,pages')
          .in_('id', hinooIds);

      final List<_CampanelloEntry> entries = [];
      for (final row in (hinooRows as List)) {
        if (row is! Map) continue;
        final String id = row['id']?.toString() ?? '';
        final pages = row['pages'];
        if (id.isEmpty || pages is! List || pages.isEmpty) continue;
        final firstPage = pages.first;
        if (firstPage is! Map) continue;
        final slide = HinooSlide.fromJson(
            firstPage.cast<String, dynamic>());
        final String text = slide.text.trim();
        if (text.isEmpty) continue;

        final String casaId = 'casa_$id';
        entries.add(
          _CampanelloEntry(
            campanello: CampanelloData(
              id: 'campanello_$id',
              campanelloHinooId: id,
              ownerId: user.id,
              backgroundImage: const AssetImage(userCampanelloBg),
              text: text,
              linkedHouseId: casaId,
            ),
            casa: CasaData(
              id: casaId,
              backgroundImage: _houseBackgroundProvider(slide.backgroundImage),
              bgTransform: slide.bgTransform,
              bgScale: slide.bgScale,
              bgOffsetX: slide.bgOffsetX,
              bgOffsetY: slide.bgOffsetY,
            ),
          ),
        );
      }

      if (mounted) {
        setState(() => _userEntries = entries);
      }
      if (!_checkedKnocks) {
        _checkedKnocks = true;
        final List<String> hinooIds = entries
            .map((entry) => entry.campanello.campanelloHinooId)
            .whereType<String>()
            .toList();
        await _checkPendingKnocks(hinooIds);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _userEntries = const []);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingUserEntries = false);
      }
    }
  }

  Future<void> _checkPendingKnocks(List<String> hinooIds) async {
    if (hinooIds.isEmpty) return;
    try {
      final rows = await SupabaseProvider.client
          .from('house_access')
          .select('id,target_house_tag')
          .in_('target_house_tag', hinooIds)
          .is_('granted_at', null);
      if (rows is! List || rows.isEmpty) return;
      _pendingKnockTags
        ..clear()
        ..addAll(rows
            .whereType<Map>()
            .map((row) => row['target_house_tag']?.toString() ?? '')
            .where((tag) => tag.isNotEmpty));
      final row = rows.first;
      if (row is! Map) return;
      final String targetTag = row['target_house_tag']?.toString() ?? '';
      if (targetTag.isEmpty || !mounted) return;

      final _CampanelloEntry entry = _userEntries.firstWhere(
        (item) => item.campanello.campanelloHinooId == targetTag,
        orElse: () => _CampanelloEntry(
          campanello: CampanelloData(
            id: '',
            campanelloHinooId: targetTag,
            ownerId: SupabaseProvider.client.auth.currentUser?.id,
            backgroundImage: const AssetImage(userCampanelloBg),
            text: '',
            linkedHouseId: '',
          ),
          casa: const CasaData(
            id: '',
            backgroundImage: AssetImage(defaultCasaBg),
            bgScale: 1.0,
            bgOffsetX: 0.0,
            bgOffsetY: 0.0,
          ),
        ),
      );

      final bool? openHouse = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (_) => const HonooConfirmDialog(
          title: 'Qualcuno ha bussato alla tua casa',
          confirmLabel: 'Apri',
          cancelLabel: 'Non ora',
        ),
      );

      if (openHouse != true || !mounted) return;
      final _CasaShareMode? mode = await _showShareModeDialog();
      if (mode == null || !mounted) return;
      await _saveShareMode(entry.campanello, mode);
      await SupabaseProvider.client.from('house_access').update({
        'granted_at': DateTime.now().toIso8601String(),
      }).eq('target_house_tag', targetTag);
      _pendingKnockTags.remove(targetTag);
      if (!mounted) return;
      showHonooToast(context, message: 'Casa aperta.');
    } catch (_) {}
  }

  @override
  void dispose() {
    _pageController.dispose();
    _campanelloPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HonooColor.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double maxWidth = constraints.maxWidth;
          final double maxHeight = constraints.maxHeight;
          final ResponsiveLayoutMode layoutMode =
              ResponsiveLayout.modeForWidth(maxWidth);
          final double targetMaxWidth = layoutMode == ResponsiveLayoutMode.mobile
              ? maxWidth
              : ResponsiveLayout.contentMaxWidth(maxWidth);

          final double footerIconSize =
              ResponsiveLayout.footerIconSizeForMode(layoutMode);
          final double footerGap = ResponsiveLayout.footerGapForMode(layoutMode);
          final bool isMobile = layoutMode == ResponsiveLayoutMode.mobile;
          final double footerBottomPadding =
              ResponsiveLayout.footerBottomPaddingForMode(layoutMode) +
                  (isMobile ? 0 : 12);
          final double safeBottom = MediaQuery.of(context).viewPadding.bottom;
          final double footerSpacing = footerBottomPadding + safeBottom;
          final double footerTopSpacing = footerSpacing / 2;
          final double footerBottomSpacing =
              footerSpacing - footerTopSpacing;

          final double footerReserved =
              footerIconSize + footerTopSpacing + footerBottomSpacing;
          final double availableHeight =
              (maxHeight - footerReserved)
                  .clamp(0.0, double.infinity);
          final double scrignoSize = math.min(
            footerIconSize * 4,
            math.min(maxWidth, availableHeight),
          );
          final Size canvasSize = ResponsiveLayout.fitAspectRatio(
            targetMaxWidth,
            availableHeight,
            HinooTypography.aspectRatio,
          );
          final double casaWidth = isMobile ? maxWidth : canvasSize.width;
          final double casaHeight =
              isMobile ? availableHeight : canvasSize.height;
          final List<_CampanelloEntry> campanelli = _buildCampanelli();
          final List<_CampanelloPageData> campanelloPages =
              _buildCampanelloPages(campanelli);
          final int safeCampanelloIndex =
              _campanelloIndex.clamp(0, campanelloPages.length - 1);
          final int houseCampanelloIndex =
              safeCampanelloIndex == 0 ? 1 : safeCampanelloIndex;
          final int casaIndex =
              (houseCampanelloIndex - 1).clamp(0, campanelli.length - 1);
          final bool showCampanello = safeCampanelloIndex > 0;
          final bool showFooter = _verticalPageIndex == 0;
          final CampanelloData? activeCampanello = showCampanello
              ? campanelli[casaIndex].campanello
              : null;
          final String? activeCampanelloId =
              activeCampanello?.campanelloHinooId;
          final bool hasPendingKnock = activeCampanelloId != null &&
              _pendingKnockTags.contains(activeCampanelloId);
          final bool casaUnlocked = activeCampanello == null
              ? false
              : _isCampanelloUnlocked(activeCampanello.id);
          final VoidCallback? scrignoTap = activeCampanello == null
              ? null
              : () => _handleScrigno(activeCampanello);
          final ScrollPhysics pagePhysics = const PageScrollPhysics()
              .applyTo(const BouncingScrollPhysics());
          const int verticalPages = 2;
          final int maxCampanelloIndex =
              math.max(0, campanelloPages.length - 1);
          const int maxVerticalIndex = verticalPages - 1;

          return FocusableActionDetector(
            autofocus: true,
            shortcuts: {
              LogicalKeySet(LogicalKeyboardKey.arrowLeft):
                  const _ArrowIntent(Axis.horizontal, -1),
              LogicalKeySet(LogicalKeyboardKey.arrowRight):
                  const _ArrowIntent(Axis.horizontal, 1),
              LogicalKeySet(LogicalKeyboardKey.arrowUp):
                  const _ArrowIntent(Axis.vertical, -1),
              LogicalKeySet(LogicalKeyboardKey.arrowDown):
                  const _ArrowIntent(Axis.vertical, 1),
            },
            actions: {
              _ArrowIntent: CallbackAction<_ArrowIntent>(
                onInvoke: (intent) {
                  if (intent.axis == Axis.horizontal &&
                      _verticalPageIndex == 0) {
                    _animatePage(
                      _campanelloPageController,
                      delta: intent.delta,
                      maxIndex: maxCampanelloIndex,
                    );
                  } else if (intent.axis == Axis.vertical) {
                    _animatePage(
                      _pageController,
                      delta: intent.delta,
                      maxIndex: maxVerticalIndex,
                    );
                  }
                  return null;
                },
              ),
            },
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  height: availableHeight,
                  child: Listener(
                    onPointerSignal: (event) {
                      if (event is PointerScrollEvent &&
                          !_isHoveringCampanelli) {
                        _handlePointerScroll(
                          _pageController,
                          event,
                          Axis.vertical,
                        );
                      }
                    },
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                          PointerDeviceKind.stylus,
                          PointerDeviceKind.trackpad,
                        },
                      ),
                      child: PageView(
                        controller: _pageController,
                        scrollDirection: Axis.vertical,
                        physics: pagePhysics,
                        onPageChanged: (index) {
                          if (index == 1) {
                            _lastHouseCampanelloIndex =
                                _campanelloIndex == 0 ? 1 : _campanelloIndex;
                          }
                          if (index == 0 && _campanelloIndex == 0) {
                            final target = _lastHouseCampanelloIndex;
                            if (_campanelloPageController.hasClients) {
                              _campanelloPageController.jumpToPage(target);
                            }
                            setState(() {
                              _verticalPageIndex = index;
                              _campanelloIndex = target;
                            });
                            return;
                          }
                          setState(() => _verticalPageIndex = index);
                        },
                        children: [
                          Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 90),
                              curve: Curves.easeOutCubic,
                              constraints:
                                  BoxConstraints(maxWidth: targetMaxWidth),
                              child: SizedBox(
                                width: canvasSize.width,
                                height: canvasSize.height,
                                child: MouseRegion(
                                  onEnter: (_) => _isHoveringCampanelli = true,
                                  onExit: (_) =>
                                      _isHoveringCampanelli = false,
                                  child: Listener(
                                    onPointerSignal: (event) {
                                      if (event is PointerScrollEvent) {
                                        _handlePointerScroll(
                                          _campanelloPageController,
                                          event,
                                          Axis.horizontal,
                                        );
                                      }
                                    },
                                    child: ScrollConfiguration(
                                      behavior:
                                          ScrollConfiguration.of(context)
                                              .copyWith(
                                        dragDevices: {
                                          PointerDeviceKind.touch,
                                          PointerDeviceKind.mouse,
                                          PointerDeviceKind.stylus,
                                          PointerDeviceKind.trackpad,
                                        },
                                      ),
                                      child: PageView.builder(
                                        controller: _campanelloPageController,
                                        scrollDirection: Axis.horizontal,
                                        physics: pagePhysics,
                                        itemCount: campanelloPages.length,
                                        onPageChanged: (index) {
                                          setState(
                                              () => _campanelloIndex = index);
                                        },
                                        itemBuilder: (context, pageIndex) {
                                          return _CampanelloCard(
                                            data: campanelloPages[pageIndex],
                                            width: canvasSize.width,
                                            height: canvasSize.height,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          casaUnlocked
                              ? AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 280),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeOutCubic,
                                  transitionBuilder: (child, animation) {
                                    final offsetAnimation = Tween<Offset>(
                                      begin: const Offset(0, 0.08),
                                      end: Offset.zero,
                                    ).animate(animation);
                                    return SlideTransition(
                                      position: offsetAnimation,
                                      child: FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Center(
                                    child: _CasaSection(
                                      key: ValueKey(
                                        '${campanelli[casaIndex].casa.id}_open',
                                      ),
                                      casa: campanelli[casaIndex].casa,
                                      isUnlocked: casaUnlocked,
                                      scrignoAsset: scrignoOverlay,
                                      onScrignoTap: scrignoTap,
                                      footerIconSize: footerIconSize,
                                      scrignoSize: scrignoSize,
                                      footerBottomSpacing: footerBottomSpacing,
                                      width: casaWidth,
                                      height: casaHeight,
                                    ),
                                  ),
                                )
                              : Center(
                                  child: _CasaSection(
                                    key: ValueKey(
                                      '${campanelli[casaIndex].casa.id}_closed',
                                    ),
                                    casa: campanelli[casaIndex].casa,
                                    isUnlocked: casaUnlocked,
                                    scrignoAsset: scrignoOverlay,
                                    onScrignoTap: scrignoTap,
                                    footerIconSize: footerIconSize,
                                    scrignoSize: scrignoSize,
                                    footerBottomSpacing: footerBottomSpacing,
                                    width: casaWidth,
                                    height: casaHeight,
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (showFooter)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: ResponsiveFooterBar(
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
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (_) => const HomePage()),
                              (route) => false,
                            );
                          },
                        ),
                        if (showCampanello)
                          ResponsiveFooterAction(
                            asset: "assets/icons/campanello_bianco.png",
                            semanticsLabel: 'Campanello',
                            size: footerIconSize,
                            splashRadius: 25,
                            tooltip: 'Campanello',
                            onPressed: () => _handleKnock(activeCampanello!),
                            icon: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Image.asset(
                                  "assets/icons/campanello_bianco.png",
                                  width: footerIconSize,
                                  height: footerIconSize,
                                  fit: BoxFit.contain,
                                ),
                                if (hasPendingKnock)
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: HonooColor.background,
                                          width: 1.5,
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
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ArrowIntent extends Intent {
  const _ArrowIntent(this.axis, this.delta);

  final Axis axis;
  final int delta;
}

class CampanelloData {
  final String id;
  final String? campanelloHinooId;
  final String? ownerId;
  final ImageProvider backgroundImage;
  final String text;
  final String linkedHouseId;

  const CampanelloData({
    required this.id,
    required this.campanelloHinooId,
    required this.ownerId,
    required this.backgroundImage,
    required this.text,
    required this.linkedHouseId,
  });
}

class CasaData {
  final String id;
  final ImageProvider backgroundImage;
  final List<double>? bgTransform;
  final double bgScale;
  final double bgOffsetX;
  final double bgOffsetY;

  const CasaData({
    required this.id,
    required this.backgroundImage,
    this.bgTransform,
    required this.bgScale,
    required this.bgOffsetX,
    required this.bgOffsetY,
  });
}

class _CampanelloEntry {
  final CampanelloData campanello;
  final CasaData casa;

  const _CampanelloEntry({
    required this.campanello,
    required this.casa,
  });
}

class _CampanelloPageData {
  final bool isIntro;
  final String text;
  final CampanelloData? campanello;

  const _CampanelloPageData._({
    required this.isIntro,
    required this.text,
    this.campanello,
  });

  factory _CampanelloPageData.intro(String text) {
    return _CampanelloPageData._(isIntro: true, text: text);
  }

  factory _CampanelloPageData.campanello(CampanelloData campanello) {
    return _CampanelloPageData._(
      isIntro: false,
      text: campanello.text,
      campanello: campanello,
    );
  }
}


class _CampanelloCard extends StatelessWidget {
  const _CampanelloCard({
    required this.data,
    required this.width,
    required this.height,
  });

  final _CampanelloPageData data;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final double verticalPadding = HinooTypography.verticalPadding(width);
    final TextStyle textStyle = GoogleFonts.lora(
      fontSize: 18,
      height: HinooTypography.lineHeight,
      color: HonooColor.onBackground,
      fontWeight: FontWeight.w400,
    );

    final Widget text = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: HinooTypography.horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Center(
        child: Text(
          data.text,
          style: textStyle,
          textAlign: TextAlign.center,
        ),
      ),
    );

    if (data.isIntro) {
      return Center(
        child: SizedBox(
          width: width,
          height: height,
          child: text,
        ),
      );
    }

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image(
                image: data.campanello!.backgroundImage,
                fit: BoxFit.cover,
              ),
              text,
            ],
          ),
        ),
      ),
    );
  }
}

class _CasaSection extends StatelessWidget {
  const _CasaSection({
    super.key,
    required this.casa,
    required this.isUnlocked,
    required this.scrignoAsset,
    this.onScrignoTap,
    required this.footerIconSize,
    required this.scrignoSize,
    required this.footerBottomSpacing,
    required this.width,
    required this.height,
  });

  final CasaData casa;
  final bool isUnlocked;
  final String scrignoAsset;
  final VoidCallback? onScrignoTap;
  final double footerIconSize;
  final double scrignoSize;
  final double footerBottomSpacing;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    const double designWidth = 1080;
    const double designHeight = 1920;
    final double scaleX = width / designWidth;
    final double scaleY = height / designHeight;

    Matrix4 buildTransform() {
      final List<double>? transform = casa.bgTransform;
      if (transform != null && transform.length == 16) {
        final List<double> m = List<double>.from(transform);
        m[12] *= scaleX;
        m[13] *= scaleY;
        return Matrix4.fromList(m);
      }

      final double tx = casa.bgOffsetX * scaleX;
      final double ty = casa.bgOffsetY * scaleY;
      return Matrix4.identity()
        ..translate(tx, ty)
        ..scale(casa.bgScale);
    }

    final Matrix4 transform = buildTransform();

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isUnlocked)
            ClipRect(
              child: Transform(
                transform: transform,
                alignment: Alignment.center,
                child: Image(
                  image: casa.backgroundImage,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(color: HonooColor.background),
          if (!isUnlocked)
            Center(
              child: Text(
                'Casa chiusa',
                textAlign: TextAlign.center,
                style: GoogleFonts.lora(
                  fontSize: 18,
                  color: HonooColor.onBackground,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          Positioned(
            bottom: footerBottomSpacing,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: onScrignoTap,
                child: SizedBox(
                  width: scrignoSize,
                  height: scrignoSize,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Image.asset(scrignoAsset),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _CasaShareMode { honoo, hinoo, conversations }

extension _CasaShareModeMapper on _CasaShareMode {
  String get label {
    switch (this) {
      case _CasaShareMode.honoo:
        return 'I miei honoo';
      case _CasaShareMode.hinoo:
        return 'I miei hinoo';
      case _CasaShareMode.conversations:
        return 'Le mie conversazioni';
    }
  }

  String get dbValue {
    switch (this) {
      case _CasaShareMode.honoo:
        return 'honoo';
      case _CasaShareMode.hinoo:
        return 'hinoo';
      case _CasaShareMode.conversations:
        return 'conversations';
    }
  }

  static _CasaShareMode? fromDb(String? value) {
    switch (value) {
      case 'honoo':
        return _CasaShareMode.honoo;
      case 'hinoo':
        return _CasaShareMode.hinoo;
      case 'conversations':
        return _CasaShareMode.conversations;
      default:
        return null;
    }
  }
}

class _CasaShareDialog extends StatelessWidget {
  const _CasaShareDialog();

  @override
  Widget build(BuildContext context) {
    return HonooDialogShell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cosa vuoi condividere?',
              style: HonooDialogStyles.title(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ..._CasaShareMode.values.map(
              (mode) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(mode),
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
                      mode.label,
                      style: HonooDialogStyles.primaryAction(),
                    ),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.white54),
              child: Text(
                'Annulla',
                style: HonooDialogStyles.tertiaryAction(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
