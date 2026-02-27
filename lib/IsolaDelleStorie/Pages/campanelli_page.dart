import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:honoo/Entities/hinoo.dart';
import 'package:honoo/Services/supabase_provider.dart';
import 'package:honoo/Controller/hinoo_controller.dart';
import 'package:honoo/Utility/honoo_colors.dart';
import 'package:honoo/Utility/responsive_layout.dart';
import 'package:honoo/Utility/utility.dart';
import 'package:honoo/Widgets/honoo_dialogs.dart';
import 'package:honoo/Widgets/responsive_footer_bar.dart';
import 'package:honoo/UI/hinoo_typography.dart';
import 'package:honoo/UI/hinoo_viewer.dart';
import 'package:honoo/Widgets/honoo_app_title.dart';
import 'package:honoo/UI/honoo_card.dart';
import 'package:honoo/Entities/honoo.dart';
import 'package:honoo/Controller/honoo_controller.dart';
import 'package:honoo/Widgets/desktop_carousel_arrows.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../Pages/home_page.dart';
import '../../Pages/shared_conversations_page.dart';
import '../../Pages/shared_hinoo_page.dart';
import '../../Pages/shared_honoo_page.dart';
import '../../Pages/new_hinoo_page.dart';
import '../../Pages/new_honoo_page.dart';

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
  bool _checkingPendingKnocks = false;
  bool _isKnocking = false;
  final Set<String> _pendingKnockTags = {};
  final List<_PendingKnock> _pendingKnocks = [];
  List<String> _ownedHinooIds = const [];
  Timer? _pendingKnockRefreshTimer;
  RealtimeChannel? _ownerAccessChannel;
  RealtimeChannel? _visitorAccessChannel;
  final Map<String, Set<_CasaShareMode>> _shareModesByCampanello = {
    campanelloSirenaId: {_CasaShareMode.honoo},
    campanelloPalombaroId: {_CasaShareMode.hinoo},
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

  Future<void> _showBusyOverlay(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => HonooDialogShell(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
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
                'Attendi...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _hideBusyOverlay() {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).maybePop();
  }

  @override
  void initState() {
    super.initState();
    _loadUserEntries();
    _pendingKnockRefreshTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _refreshPendingKnocks(),
    );
    _subscribeVisitorAccessChannel();
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
    if (_isKnocking) return;
    if (_isCampanelloUnlocked(campanello.id)) {
      await _showEnterDialog(campanello.id);
      return;
    }

    final _KnockMessageChoice? choice = await _showKnockMessageDialog();
    if (choice == null || !mounted) return;

    String? hinooId;
    String? honooId;
    if (choice == _KnockMessageChoice.hinoo) {
      final String? result = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => NewHinooPage(
            forcedType: HinooType.answer,
            recipientTag: campanello.ownerId,
            returnSavedId: true,
          ),
        ),
      );
      if (!mounted) return;
      if (result == null || result.isEmpty) return;
      hinooId = result;
    } else if (choice == _KnockMessageChoice.honoo) {
      final String? result = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => NewHonooPage(
            forcedType: HonooType.answer,
            recipientTag: campanello.ownerId,
            returnSavedId: true,
          ),
        ),
      );
      if (!mounted) return;
      if (result == null || result.isEmpty) return;
      honooId = result;
    }

    setState(() => _isKnocking = true);
    try {
      await _showBusyOverlay('Invio la bussata...');
      try {
        await _sendHouseKnock(
          campanello,
          hinooId: hinooId,
          honooId: honooId,
        );
        _hideBusyOverlay();
        if (mounted) {
          showHonooToast(context, message: 'Bussata inviata. Attendi risposta.');
        }
      } catch (e) {
        debugPrint('house_access insert error: $e');
        _hideBusyOverlay();
        if (mounted) {
          showHonooToast(context, message: 'Invio non riuscito. Ritenta tra poco.');
        }
      }
    } finally {
      if (mounted) setState(() => _isKnocking = false);
    }
    // waiting realtime approval update
  }

  Future<void> _sendHouseKnock(
    CampanelloData campanello, {
    String? hinooId,
    String? honooId,
  }) async {
    final user = SupabaseProvider.client.auth.currentUser;
    final String? targetTag = campanello.campanelloHinooId;
    if (user == null || targetTag == null || targetTag.isEmpty) return;
    if (campanello.ownerId == user.id) return;

    try {
      await SupabaseProvider.client.from('house_access').insert({
        'target_house_tag': targetTag,
        'visitor_id': user.id,
        if (hinooId != null && hinooId.isNotEmpty) 'hinoo_id': hinooId,
        if (honooId != null && honooId.isNotEmpty) 'honoo_id': honooId,
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
    final double bump = position.viewportDimension * 0.5;
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
    Set<_CasaShareMode>? modes = _shareModesByCampanello[shareKey];
    final user = SupabaseProvider.client.auth.currentUser;
    final bool isOwner = user != null && campanello.ownerId == user.id;

    if ((modes == null || modes.isEmpty) && isOwner) {
      final selected = await showDialog<Set<_CasaShareMode>>(
        context: context,
        barrierDismissible: true,
        builder: (_) => _CasaMultiShareDialog(
          onConfirm: (picked) => _saveShareModes(campanello, picked),
        ),
      );
      if (selected == null || selected.isEmpty || !mounted) return;
      modes = selected;
    }

    if (!mounted) return;
    if (modes == null || modes.isEmpty) {
      showHonooToast(
        context,
        message: 'Il padrone di casa non ha ancora scelto cosa condividere.',
      );
      return;
    }

    if (modes.length == 1) {
      _openSharedContent(modes.first, campanello);
      return;
    }

    final _CasaShareMode? choice =
        await _showVisitorShareChoiceDialog(context, modes);
    if (choice != null) {
      _openSharedContent(choice, campanello);
    }
  }

  Future<Set<_CasaShareMode>?> _showOwnerMultiShareDialog() {
    return showDialog<Set<_CasaShareMode>>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _CasaMultiShareDialog(
        onConfirm: (modes) async {},
      ),
    );
  }

  

  Future<void> _saveShareModes(
    CampanelloData campanello,
    Set<_CasaShareMode> modes,
  ) async {
    final user = SupabaseProvider.client.auth.currentUser;
    final shareKey = _shareKeyFor(campanello);

    if (user == null || campanello.campanelloHinooId == null) {
      setState(() => _shareModesByCampanello[shareKey] = modes);
      return;
    }

    final List<String> values = modes.map((m) => m.dbValue).toList();
    final String? single = values.isNotEmpty ? values.first : null;
    await SupabaseProvider.client.from('house_share_settings').upsert({
      'owner_id': user.id,
      'campanello_hinoo_id': campanello.campanelloHinooId,
      'share_mode': single, // retrocompatibilità
      'share_modes': values,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'campanello_hinoo_id');

    if (!mounted) return;
    setState(() => _shareModesByCampanello[shareKey] = modes);
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

  ImageProvider _houseBackgroundProvider(
    String? houseUrl,
    String? fallbackUrl,
  ) {
    if (houseUrl != null && houseUrl.isNotEmpty) {
      return NetworkImage(houseUrl);
    }
    if (fallbackUrl != null && fallbackUrl.isNotEmpty) {
      return NetworkImage(fallbackUrl);
    }
    return const AssetImage(defaultCasaBg);
  }

  ImageProvider _campanelloBackgroundProvider(String? bgUrl) {
    if (bgUrl != null && bgUrl.isNotEmpty) {
      return NetworkImage(bgUrl);
    }
    return const AssetImage(userCampanelloBg);
  }

  List<double>? _parseTransform(dynamic raw) {
    if (raw is! List) return null;
    try {
      return raw.map((e) => (e as num).toDouble()).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadUserEntries() async {
    if (_isLoadingUserEntries) return;
    final user = SupabaseProvider.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoadingUserEntries = true);
    try {
      final rows = await SupabaseProvider.client
          .from('case')
          .select('campanello_hinoo_id,owner_id,house_image_url,bg_transform');

      final Map<String, String> ownerByHinooId = {};
      final Map<String, Map<String, dynamic>> casaByHinooId = {};
      final List<String> ownedHinooIds = [];
      for (final row in (rows as List)) {
        if (row is! Map) continue;
        final String? hinooId = row['campanello_hinoo_id'] as String?;
        final String? ownerId = row['owner_id'] as String?;
        if (hinooId == null || hinooId.isEmpty) continue;
        if (ownerId == null || ownerId.isEmpty) continue;
        ownerByHinooId[hinooId] = ownerId;
        casaByHinooId[hinooId] = Map<String, dynamic>.from(row);
        if (ownerId == user.id) {
          ownedHinooIds.add(hinooId);
        }
      }

      final List<String> hinooIds = ownerByHinooId.keys.toList();

      if (hinooIds.isEmpty) {
        if (mounted) {
          setState(() {
            _userEntries = const [];
            _ownedHinooIds = const [];
          });
        }
        return;
      }

      final shareRows = await SupabaseProvider.client
          .from('house_share_settings')
          .select('campanello_hinoo_id,share_mode,share_modes')
          .in_('campanello_hinoo_id', hinooIds);

      for (final row in (shareRows as List)) {
        if (row is! Map) continue;
        final String? hinooId = row['campanello_hinoo_id'] as String?;
        final List<dynamic>? modes = row['share_modes'] as List<dynamic>?;
        Set<_CasaShareMode> selected = {};
        if (modes != null) {
          for (final v in modes) {
            final parsed = _CasaShareModeMapper.fromDb(v?.toString());
            if (parsed != null) selected.add(parsed);
          }
        }
        if (selected.isEmpty) {
          final String? mode = row['share_mode'] as String?;
          final parsed = _CasaShareModeMapper.fromDb(mode);
          if (parsed != null) selected = {parsed};
        }
        if (hinooId != null && selected.isNotEmpty) {
          _shareModesByCampanello[hinooId] = selected;
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

        final String? ownerId = ownerByHinooId[id];
        if (ownerId == null) continue;
        final String casaId = 'casa_$id';
        final Map<String, dynamic> casaRow =
            casaByHinooId[id] ?? const <String, dynamic>{};
        final String? houseImageUrl = casaRow['house_image_url'] as String?;
        final List<double>? bgTransform =
            _parseTransform(casaRow['bg_transform']);
        entries.add(
          _CampanelloEntry(
            campanello: CampanelloData(
              id: 'campanello_$id',
              campanelloHinooId: id,
              ownerId: ownerId,
              backgroundImage: _campanelloBackgroundProvider(
                slide.backgroundImage,
              ),
              text: text,
              linkedHouseId: casaId,
            ),
            casa: CasaData(
              id: casaId,
              backgroundImage:
                  _houseBackgroundProvider(houseImageUrl, slide.backgroundImage),
              bgTransform: bgTransform,
              bgScale: slide.bgScale,
              bgOffsetX: slide.bgOffsetX,
              bgOffsetY: slide.bgOffsetY,
            ),
          ),
        );
      }

      if (mounted) {
        setState(() {
          _userEntries = entries;
          _ownedHinooIds = List<String>.from(ownedHinooIds);
          _unlockedCampanelli.addAll(
            entries
                .where((entry) => entry.campanello.ownerId == user.id)
                .map((entry) => entry.campanello.id),
          );
        });
      }
      _subscribeOwnerAccessChannel();
      if (!_checkedKnocks) {
        _checkedKnocks = true;
        await _checkPendingKnocks(ownedHinooIds);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _userEntries = const [];
          _ownedHinooIds = const [];
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingUserEntries = false);
      }
    }
  }

  void _subscribeOwnerAccessChannel() {
    try {
      final user = SupabaseProvider.client.auth.currentUser;
      if (user == null) return;
      // Re-subscribe if needed
      _ownerAccessChannel?.unsubscribe();
      _ownerAccessChannel = SupabaseProvider.client.channel('house-access-owner-${user.id}')
        ..on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: 'INSERT',
            schema: 'public',
            table: 'house_access',
          ),
          (payload, [ref]) {
            try {
              final Map? record = payload is Map ? payload['new'] as Map? : null;
              if (record == null) return;
              final String? tag = record['target_house_tag']?.toString();
              final dynamic granted = record['granted_at'];
              if (tag == null || tag.isEmpty) return;
              if (!_ownedHinooIds.contains(tag)) return;
              if (granted != null) return; // only pending knocks
              // Append pending knock and show toast
              final String id = record['id']?.toString() ?? '';
              final String? raw = record['created_at']?.toString();
              final DateTime createdAt =
                  raw == null || raw.isEmpty ? DateTime.now() : DateTime.parse(raw);
              final String? hinooId = record['hinoo_id']?.toString();
              final String? honooId = record['honoo_id']?.toString();
              if (!mounted) return;
              setState(() {
                _pendingKnocks.add(
                  _PendingKnock(
                    id: id,
                    targetTag: tag,
                    createdAt: createdAt,
                    hinooId: hinooId,
                    honooId: honooId,
                  ),
                );
                _pendingKnockTags.add(tag);
              });
              showHonooToast(context, message: 'Qualcuno ha bussato alla tua casa');
            } catch (_) {}
          },
        )
        ..on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: 'DELETE',
            schema: 'public',
            table: 'house_access',
          ),
          (payload, [ref]) {
            // keep local list in sync if deletions happen
            try {
              final Map? oldRec = payload is Map ? payload['old'] as Map? : null;
              if (oldRec == null) return;
              final String? id = oldRec['id']?.toString();
              if (id == null) return;
              if (!mounted) return;
              setState(() {
                _pendingKnocks.removeWhere((k) => k.id == id);
                _pendingKnockTags
                  ..clear()
                  ..addAll(_pendingKnocks.map((k) => k.targetTag));
              });
            } catch (_) {}
          },
        )
        ..subscribe();
    } catch (_) {
      // In test or when Realtime not available, safely ignore
    }
  }

  void _subscribeVisitorAccessChannel() {
    try {
      final user = SupabaseProvider.client.auth.currentUser;
      if (user == null) return;
      _visitorAccessChannel?.unsubscribe();
      _visitorAccessChannel = SupabaseProvider.client.channel('house-access-visitor-${user.id}')
        ..on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: 'UPDATE',
            schema: 'public',
            table: 'house_access',
            filter: 'visitor_id=eq.${user.id}',
          ),
          (payload, [ref]) async {
            try {
              final Map? record = payload is Map ? payload['new'] as Map? : null;
              if (record == null) return;
              final dynamic granted = record['granted_at'];
              if (granted == null) return;
              final String? tag = record['target_house_tag']?.toString();
              if (tag == null || tag.isEmpty) return;
              if (!mounted) return;
              showHonooToast(context, message: 'La casa è stata aperta');
              await _goToCampanelloByTag(tag);
              await _hintCampanelloBounce();
              // unlock the specific campanello for this session
              final entry = _entryForTag(tag);
              if (entry != null && mounted) {
                setState(() => _unlockedCampanelli.add(entry.campanello.id));
              }
            } catch (_) {}
          },
        )
        ..subscribe();
    } catch (_) {
      // In test or when Realtime not available, safely ignore
    }
  }

  Future<void> _goToCampanelloByTag(String tag) async {
    final List<_CampanelloEntry> campanelli = _buildCampanelli();
    final int idx = campanelli.indexWhere(
      (e) => e.campanello.campanelloHinooId == tag,
    );
    if (idx < 0) return;
    // Horizontal PageView uses a pages list with an intro at index 0
    final int pageIndex = idx + 1;
    // Ensure we are on the campanelli layer (vertical page 0)
    if (_pageController.hasClients) {
      await _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
    if (_campanelloPageController.hasClients) {
      await _campanelloPageController.animateToPage(
        pageIndex,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
      if (mounted) setState(() => _campanelloIndex = pageIndex);
    }
  }

  Future<void> _hintCampanelloBounce() async {
    if (!_campanelloPageController.hasClients) return;
    final position = _campanelloPageController.position;
    final double bump = (position.viewportDimension * 0.08).clamp(6.0, 60.0);
    final double start = position.pixels;
    final double target = (start + bump)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    try {
      await _campanelloPageController.animateTo(
        target,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
      await _campanelloPageController.animateTo(
        start,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {}
  }

  Future<void> _checkPendingKnocks(List<String> hinooIds) async {
    if (hinooIds.isEmpty) return;
    try {
      final rows = await SupabaseProvider.client
          .from('house_access')
          .select('id,target_house_tag,created_at,hinoo_id,honoo_id')
          .in_('target_house_tag', hinooIds)
          .is_('granted_at', null);
      if (rows is! List) return;
      if (rows.isEmpty) {
        if (!mounted) return;
        setState(() {
          _pendingKnocks.clear();
          _pendingKnockTags.clear();
        });
        return;
      }
      final List<_PendingKnock> knocks = [];
      for (final row in rows.whereType<Map>()) {
        final String id = row['id']?.toString() ?? '';
        final String tag = row['target_house_tag']?.toString() ?? '';
        if (id.isEmpty || tag.isEmpty) continue;
        final String? raw = row['created_at']?.toString();
        final DateTime createdAt =
            raw == null || raw.isEmpty ? DateTime.now() : DateTime.parse(raw);
        final String? hinooId = row['hinoo_id']?.toString();
        final String? honooId = row['honoo_id']?.toString();
        knocks.add(
          _PendingKnock(
            id: id,
            targetTag: tag,
            createdAt: createdAt,
            hinooId: hinooId,
            honooId: honooId,
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _pendingKnocks
          ..clear()
          ..addAll(knocks);
        _pendingKnockTags
          ..clear()
          ..addAll(knocks.map((k) => k.targetTag));
      });
    } catch (_) {}
  }

  Future<void> _refreshPendingKnocks() async {
    if (_checkingPendingKnocks) return;
    if (_ownedHinooIds.isEmpty) return;
    _checkingPendingKnocks = true;
    try {
      await _checkPendingKnocks(_ownedHinooIds);
    } finally {
      _checkingPendingKnocks = false;
    }
  }

  _CampanelloEntry? _entryForTag(String? tag) {
    if (tag == null || tag.isEmpty) return null;
    for (final entry in _userEntries) {
      if (entry.campanello.campanelloHinooId == tag) return entry;
    }
    return null;
  }

  String _pendingLabelForTag(String? tag) {
    final entry = _entryForTag(tag);
    if (entry == null) return 'Campanello';
    final String raw = entry.campanello.text.trim();
    if (raw.isEmpty) return 'Campanello';
    final String firstLine = raw.split('\n').first.trim();
    return firstLine.isEmpty ? 'Campanello' : firstLine;
  }

  String _formatPendingTimestamp(DateTime ts) {
    final DateTime local = ts.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  Future<HinooDraft?> _fetchHinooDraft(String hinooId) async {
    final row = await SupabaseProvider.client
        .from('hinoo')
        .select('pages,type,recipient_tag,created_at')
        .eq('id', hinooId)
        .maybeSingle();
    if (row == null || row['pages'] is! List) return null;
    final List<dynamic> pages = row['pages'] as List;
    return HinooDraft(
      pages: pages
          .whereType<Map<String, dynamic>>()
          .map((entry) => HinooSlide.fromJson(entry))
          .toList(),
      type: HinooType.answer,
      recipientTag: row['recipient_tag'] as String?,
    );
  }

  Future<Honoo?> _fetchHonoo(String honooId) async {
    final row = await SupabaseProvider.client
        .from('honoo')
        .select('id,text,image_url,destination,reply_to,recipient_tag,created_at,updated_at,user_id')
        .eq('id', honooId)
        .maybeSingle();
    if (row == null) return null;
    return Honoo.fromMap(row.cast<String, dynamic>());
  }

  Future<void> _approvePendingKnock(
    _PendingKnock knock,
    _CampanelloEntry entry, {
    HinooDraft? draft,
    Honoo? honoo,
  }) async {
    await _showBusyOverlay('Apro la casa...');
    try {
      final Set<_CasaShareMode>? modes = await _showOwnerMultiShareDialog();
      if (modes == null || modes.isEmpty || !mounted) return _hideBusyOverlay();
      await _saveShareModes(entry.campanello, modes);
      try {
        await SupabaseProvider.client.from('house_access').update({
          'granted_at': DateTime.now().toIso8601String(),
        }).eq('id', knock.id);
      } catch (e) {
        debugPrint('house_access grant error: $e');
        showHonooToast(context, message: 'Operazione non riuscita. Ritenta.');
        return _hideBusyOverlay();
      }
    } finally {
      _hideBusyOverlay();
    }

    if (draft != null) {
      try {
        final HinooDraft personalDraft =
            draft.copyWith(type: HinooType.personal, recipientTag: null);
        await HinooController().saveToChest(personalDraft);
      } catch (_) {}
    }

    if (honoo != null) {
      try {
        await HonooController().saveToChest(honoo);
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _pendingKnocks.removeWhere((item) => item.id == knock.id);
      _pendingKnockTags
        ..clear()
        ..addAll(_pendingKnocks.map((item) => item.targetTag));
    });
    showHonooToast(context, message: 'Casa aperta.');
  }

  Future<void> _openPendingKnock(_PendingKnock knock) async {
    final entry = _entryForTag(knock.targetTag);
    if (entry == null) return;
    if (knock.hinooId == null && knock.honooId == null) {
      final bool? openHouse = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (_) => const HonooConfirmDialog(
          title: 'Qualcuno ha bussato alla tua casa',
          confirmLabel: 'Apri',
          cancelLabel: 'Non ora',
        ),
      );

      if (openHouse == true && mounted) {
        await _approvePendingKnock(knock, entry);
      }
      return;
    }

    if (knock.hinooId != null && knock.hinooId!.isNotEmpty) {
      final draft = await _fetchHinooDraft(knock.hinooId!);
      if (draft == null || !mounted) return;
      final bool? approved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => _PendingHinooPage(draft: draft),
        ),
      );

      if (approved == true && mounted) {
        await _approvePendingKnock(knock, entry, draft: draft);
      }
      return;
    }

    if (knock.honooId != null && knock.honooId!.isNotEmpty) {
      final honoo = await _fetchHonoo(knock.honooId!);
      if (honoo == null || !mounted) return;
      final bool? approved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => _PendingHonooPage(honoo: honoo),
        ),
      );

      if (approved == true && mounted) {
        await _approvePendingKnock(knock, entry, honoo: honoo);
      }
    }
  }

  Future<_KnockMessageChoice?> _showKnockMessageDialog() {
    return showDialog<_KnockMessageChoice>(
      context: context,
      barrierDismissible: true,
      builder: (_) => HonooDialogShell(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Vuoi inviare un messaggio\nprima di bussare?',
                style: HonooDialogStyles.title(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).pop(_KnockMessageChoice.hinoo),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Scrivi un hinoo',
                    style: HonooDialogStyles.primaryAction(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).pop(_KnockMessageChoice.honoo),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Scrivi un honoo',
                    style: HonooDialogStyles.primaryAction(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(_KnockMessageChoice.none),
                style: TextButton.styleFrom(foregroundColor: Colors.white70),
                child: Text(
                  'No, bussa e basta',
                  style: HonooDialogStyles.tertiaryAction(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPendingKnocksDialog() async {
    if (_pendingKnocks.isEmpty) return;
    final List<_PendingKnock> sorted = List<_PendingKnock>.from(_pendingKnocks)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => HonooDialogShell(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bussate in attesa',
                style: HonooDialogStyles.title(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final knock in sorted)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await _openPendingKnock(knock);
                              },
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
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _pendingLabelForTag(knock.targetTag),
                                    style: HonooDialogStyles.primaryAction(),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: () async {
                                      Navigator.of(context).pop();
                                      await _openPendingKnock(knock);
                                    },
                                    child: Text(
                                      _formatPendingTimestamp(knock.createdAt),
                                      style:
                                          HonooDialogStyles.tertiaryAction(),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(foregroundColor: Colors.white54),
                child: Text(
                  'Chiudi',
                  style: HonooDialogStyles.tertiaryAction(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pendingKnockRefreshTimer?.cancel();
    _ownerAccessChannel?.unsubscribe();
    _visitorAccessChannel?.unsubscribe();
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
          final user = SupabaseProvider.client.auth.currentUser;
          final String? activeCampanelloId =
              activeCampanello?.campanelloHinooId;
          final bool hasPendingKnock = activeCampanelloId != null &&
              _pendingKnockTags.contains(activeCampanelloId);
          final bool hasAnyPendingKnock = _pendingKnockTags.isNotEmpty;
          final int pendingKnockCount = _pendingKnocks.length;
          final bool casaUnlocked = activeCampanello == null
              ? false
              : _isCampanelloUnlocked(activeCampanello.id);
          final VoidCallback? scrignoTap = activeCampanello == null
              ? null
              : () => _handleScrigno(activeCampanello);
          final bool isOwnCampanello = activeCampanello != null &&
              user != null &&
              activeCampanello.ownerId == user.id;
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
                          if (index == 0) {
                            final int target = _campanelloIndex == 0
                                ? _lastHouseCampanelloIndex
                                : _campanelloIndex;
                            if (target > 0 &&
                                _campanelloPageController.hasClients) {
                              _campanelloPageController.jumpToPage(target);
                            }
                            setState(() {
                              _verticalPageIndex = index;
                              if (target > 0) _campanelloIndex = target;
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
                                      child: () {
                                        final pv = PageView.builder(
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
                                        );
                                        final bool isDesktop =
                                            layoutMode ==
                                                    ResponsiveLayoutMode
                                                        .desktop ||
                                                layoutMode ==
                                                    ResponsiveLayoutMode
                                                        .wideDesktop ||
                                                layoutMode ==
                                                    ResponsiveLayoutMode
                                                        .largeDesktop;
                                        if (!isDesktop ||
                                            campanelloPages.length <= 1) {
                                          return pv;
                                        }
                                        return DesktopCarouselArrows(
                                          canPrev: _campanelloIndex > 0,
                                          canNext: _campanelloIndex <
                                              campanelloPages.length - 1,
                                          onPrev: () => _animatePage(
                                            _campanelloPageController,
                                            delta: -1,
                                            maxIndex: maxCampanelloIndex,
                                          ),
                                          onNext: () => _animatePage(
                                            _campanelloPageController,
                                            delta: 1,
                                            maxIndex: maxCampanelloIndex,
                                          ),
                                          arrowColor: Colors.white,
                                          child: pv,
                                        );
                                      }(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ),
                          casaUnlocked
                              ? AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 480),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeOutCubic,
                                  transitionBuilder: (child, animation) {
                                    final curved = CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.elasticOut,
                                    );
                                    final offsetAnimation = Tween<Offset>(
                                      begin: const Offset(0, 0.28),
                                      end: Offset.zero,
                                    ).animate(curved);
                                    final scale = Tween<double>(
                                      begin: 0.97,
                                      end: 1.0,
                                    ).animate(curved);
                                    return SlideTransition(
                                      position: offsetAnimation,
                                      child: ScaleTransition(
                                        scale: scale,
                                        child: FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        ),
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
                        if (showCampanello && !isOwnCampanello && !_isKnocking)
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
                                    top: -4,
                                    right: -4,
                                    child: _PendingKnockBadge(
                                      count: pendingKnockCount,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        if (showCampanello && !isOwnCampanello && _isKnocking)
                          ResponsiveFooterAction(
                            asset: "assets/icons/campanello_bianco.png",
                            semanticsLabel: 'Campanello',
                            size: footerIconSize,
                            splashRadius: 25,
                            tooltip: 'Campanello',
                            onPressed: null,
                            icon: SizedBox(
                              width: footerIconSize,
                              height: footerIconSize,
                            ),
                          ),
                        if (!showCampanello && hasAnyPendingKnock)
                          ResponsiveFooterAction(
                            asset: "assets/icons/campanello_bianco.png",
                            semanticsLabel: 'Campanelli',
                            size: footerIconSize,
                            splashRadius: 25,
                            tooltip: 'Bussate in attesa',
                            onPressed: _openPendingKnocksDialog,
                            icon: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Image.asset(
                                  "assets/icons/campanello_bianco.png",
                                  width: footerIconSize,
                                  height: footerIconSize,
                                  fit: BoxFit.contain,
                                ),
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: _PendingKnockBadge(
                                    count: pendingKnockCount,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (!showCampanello && !hasAnyPendingKnock)
                          ResponsiveFooterAction(
                            asset: "assets/icons/campanello_bianco.png",
                            semanticsLabel: 'Campanelli',
                            size: footerIconSize,
                            splashRadius: 25,
                            tooltip: 'Bussate in attesa',
                            onPressed: null,
                            icon: SizedBox(
                              width: footerIconSize,
                              height: footerIconSize,
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

class _PendingHinooPage extends StatelessWidget {
  const _PendingHinooPage({required this.draft});

  final HinooDraft draft;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HonooColor.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double viewW = constraints.maxWidth;
          final double viewH = constraints.maxHeight;
          final double safeBottom = MediaQuery.of(context).viewPadding.bottom;
          final layoutMode = ResponsiveLayout.modeForWidth(viewW);
          final double footerIconSize =
              ResponsiveLayout.footerIconSizeForMode(layoutMode);
          final double footerGap = ResponsiveLayout.footerGapForMode(layoutMode);
          final double footerBottomPadding =
              ResponsiveLayout.footerBottomPaddingForMode(layoutMode);
          final double footerSpacing = footerBottomPadding + safeBottom;
          final double footerTopSpacing = footerSpacing / 2;
          final double footerBottomSpacing = footerSpacing - footerTopSpacing;
          const double headerH = 52;
          final double targetMaxW = viewW;
          final double footerReserved =
              footerIconSize + footerTopSpacing + footerBottomSpacing;
          final double availableH =
              (viewH - headerH - footerReserved).clamp(0.0, double.infinity);

          return Column(
            children: [
              SizedBox(
                height: headerH,
                child: Center(
                  child: HonooAppTitle(
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: targetMaxW,
                    height: availableH,
                    child: HinooViewer(
                      draft: draft,
                      maxHeight: availableH,
                      maxWidth: targetMaxW,
                    ),
                  ),
                ),
              ),
              SizedBox(height: footerTopSpacing),
              ResponsiveFooterBar(
                useSafeArea: false,
                bottomPadding: footerBottomSpacing,
                desiredGap: footerGap,
                minGap: 16,
                height: footerIconSize,
                actions: [
                  ResponsiveFooterAction(
                    asset: "assets/icons/cancella.svg",
                    semanticsLabel: 'Annulla',
                    size: footerIconSize,
                    splashRadius: 25,
                    tooltip: 'Non ora',
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  ResponsiveFooterAction(
                    asset: "assets/icons/ok.svg",
                    semanticsLabel: 'OK',
                    size: footerIconSize,
                    splashRadius: 25,
                    tooltip: 'Apri',
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PendingHonooPage extends StatelessWidget {
  const _PendingHonooPage({required this.honoo});

  final Honoo honoo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HonooColor.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double viewW = constraints.maxWidth;
          final double viewH = constraints.maxHeight;
          final double safeBottom = MediaQuery.of(context).viewPadding.bottom;
          final layoutMode = ResponsiveLayout.modeForWidth(viewW);
          final double footerIconSize =
              ResponsiveLayout.footerIconSizeForMode(layoutMode);
          final double footerGap = ResponsiveLayout.footerGapForMode(layoutMode);
          final double footerBottomPadding =
              ResponsiveLayout.footerBottomPaddingForMode(layoutMode);
          final double footerSpacing = footerBottomPadding + safeBottom;
          final double footerTopSpacing = footerSpacing / 2;
          final double footerBottomSpacing = footerSpacing - footerTopSpacing;
          const double headerH = 52;
          final double targetMaxW = ResponsiveLayout.contentMaxWidth(viewW);
          final double footerReserved =
              footerIconSize + footerTopSpacing + footerBottomSpacing;
          final double availableH =
              (viewH - headerH - footerReserved).clamp(0.0, double.infinity);
          final HonooBuilderMetrics metrics =
              ResponsiveLayout.honooBuilderMetrics(
            availableHeight: availableH,
            maxWidth: targetMaxW,
            mode: layoutMode,
          );

          return Column(
            children: [
              SizedBox(
                height: headerH,
                child: Center(
                  child: HonooAppTitle(
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: metrics.width,
                    height: metrics.height,
                    child: HonooCard(honoo: honoo),
                  ),
                ),
              ),
              SizedBox(height: footerTopSpacing),
              ResponsiveFooterBar(
                useSafeArea: false,
                bottomPadding: footerBottomSpacing,
                desiredGap: footerGap,
                minGap: 16,
                height: footerIconSize,
                actions: [
                  ResponsiveFooterAction(
                    asset: "assets/icons/cancella.svg",
                    semanticsLabel: 'Annulla',
                    size: footerIconSize,
                    splashRadius: 25,
                    tooltip: 'Non ora',
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  ResponsiveFooterAction(
                    asset: "assets/icons/ok.svg",
                    semanticsLabel: 'OK',
                    size: footerIconSize,
                    splashRadius: 25,
                    tooltip: 'Apri',
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PendingKnock {
  final String id;
  final String targetTag;
  final DateTime createdAt;
  final String? hinooId;
  final String? honooId;

  const _PendingKnock({
    required this.id,
    required this.targetTag,
    required this.createdAt,
    this.hinooId,
    this.honooId,
  });
}

enum _KnockMessageChoice { none, honoo, hinoo }

class _ArrowIntent extends Intent {
  const _ArrowIntent(this.axis, this.delta);

  final Axis axis;
  final int delta;
}

class _PendingKnockBadge extends StatelessWidget {
  const _PendingKnockBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final String label = count > 99 ? '99+' : count.toString();
    final double size = count > 9 ? 18 : 16;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      height: size,
      constraints: BoxConstraints(minWidth: size),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(
          color: HonooColor.background,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.libreFranklin(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
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

// (Rimosso il vecchio dialogo single-choice non più usato)

class _CasaMultiShareDialog extends StatefulWidget {
  const _CasaMultiShareDialog({required this.onConfirm});

  final Future<void> Function(Set<_CasaShareMode> modes) onConfirm;

  @override
  State<_CasaMultiShareDialog> createState() => _CasaMultiShareDialogState();
}

class _CasaMultiShareDialogState extends State<_CasaMultiShareDialog> {
  final Set<_CasaShareMode> _selected = {};
  bool _saving = false;

  void _toggle(_CasaShareMode mode) {
    setState(() {
      if (_selected.contains(mode)) {
        _selected.remove(mode);
      } else {
        _selected.add(mode);
      }
    });
  }

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
                  child: OutlinedButton(
                    onPressed: () => _toggle(mode),
                    style: OutlinedButton.styleFrom(
                      backgroundColor:
                          _selected.contains(mode) ? Colors.white : Colors.transparent,
                      foregroundColor: Colors.black,
                      side: BorderSide(
                        color: _selected.contains(mode)
                            ? Colors.white
                            : Colors.white24,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_selected.contains(mode))
                          const Icon(Icons.check, size: 18),
                        if (_selected.contains(mode)) const SizedBox(width: 8),
                        Text(
                          mode.label,
                          style: HonooDialogStyles.primaryAction(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            if (_saving)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: null,
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              const AlwaysStoppedAnimation(Colors.black),
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Salvo...',
                        style: HonooDialogStyles.primaryAction(),
                      ),
                    ],
                  ),
                ),
              )
            else if (_selected.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    setState(() => _saving = true);
                    try {
                      await widget.onConfirm(_selected);
                      if (!mounted) return;
                      Navigator.of(context).pop(_selected);
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
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
                    'Condividi',
                    style: HonooDialogStyles.primaryAction(),
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

  Future<_CasaShareMode?> _showVisitorShareChoiceDialog(
    BuildContext context,
    Set<_CasaShareMode> modes,
  ) async {
    return showDialog<_CasaShareMode>(
      context: context,
      barrierDismissible: true,
      builder: (_) => HonooDialogShell(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cosa vuoi aprire?',
                style: HonooDialogStyles.title(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ...modes.map(
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
                  'Chiudi',
                  style: HonooDialogStyles.tertiaryAction(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
