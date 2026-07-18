import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:honoo/Entities/hinoo.dart';
import 'package:honoo/Entities/pending_knock.dart';
import 'package:honoo/Services/supabase_provider.dart';
import 'package:honoo/Controller/hinoo_controller.dart';
import 'package:honoo/Controller/campanelli_controller.dart';
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
import 'package:honoo/Widgets/busy_overlay.dart';
import 'package:honoo/Services/admin_service.dart';
import 'package:honoo/Services/house_access_service.dart';
import 'package:honoo/Services/campanelli_repository.dart';

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
  final HouseAccessService _houseAccessService = const HouseAccessService();
  final CampanelliDataRepository _campanelliRepository =
      CampanelliDataRepository();
  late final CampanelliController _campanelliController =
      CampanelliController(repository: _campanelliRepository);
  // Animations: centralize durations/curves to avoid magic numbers
  static const Duration _kAnimFast = Duration(milliseconds: 220);
  static const Duration _kAnimMed = Duration(milliseconds: 240);
  static const Duration _kBounceIn = Duration(milliseconds: 180);
  static const Duration _kBounceOut = Duration(milliseconds: 200);
  static const Curve _kCurve = Curves.easeOutCubic;
  int _campanelloIndex = 0;
  int _verticalPageIndex = 0;
  int _lastHouseCampanelloIndex = 1;
  final PageController _pageController = PageController();
  final PageController _campanelloPageController = PageController();
  List<_CampanelloEntry> _userEntries = const [];
  bool _isLoadingUserEntries = false;
  bool _isHoveringCampanelli = false;
  bool _isKnocking = false;
  bool get _hasOwnHouse => _campanelliController.state.hasOwnHouse;
  bool get _hasPendingOrAcceptedInvite =>
      _campanelliController.state.hasPendingOrAcceptedInvite;
  DateTime? _lastKnockToastAt;
  List<PendingKnock> get _pendingKnocks =>
      _campanelliController.state.pendingKnocks;
  Set<String> get _pendingKnockTags => _campanelliController.pendingKnockTags;
  List<String> _ownedHinooIds = const [];
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
      builder: (_) => BusyOverlay(message: message),
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
    controller.animateToPage(target, duration: _kAnimFast, curve: _kCurve);
  }

  Future<void> _handleKnock(CampanelloData campanello) async {
    if (_isKnocking) return;
    // Light haptic feedback on knock intent
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
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
          showHonooToast(context,
              message: 'Bussata inviata. Attendi risposta.');
        }
      } catch (e) {
        debugPrint('house_access insert error: $e');
        _hideBusyOverlay();
        if (mounted) {
          showHonooToast(context,
              message: 'Invio non riuscito. Ritenta tra poco.');
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
      await _houseAccessService.sendKnock(
        targetHouseTag: targetTag,
        visitorId: user.id,
        hinooId: hinooId,
        honooId: honooId,
      );
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

    await _pageController.animateTo(target,
        duration: _kAnimFast, curve: _kCurve);
    await _pageController.animateTo(start, duration: _kAnimMed, curve: _kCurve);
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
    await _houseAccessService.saveShareModes(
      ownerId: user.id,
      campanelloHinooId: campanello.campanelloHinooId!,
      modes: values,
    );

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

  Future<void> _handleInviteRequestTap() async {
    if (!_campanelliController.beginInviteRequest()) return;
    try {
      if (_hasOwnHouse) {
        if (mounted) {
          showHonooToast(context, message: 'Hai già una casa.');
        }
        return;
      }
      if (_hasPendingOrAcceptedInvite) {
        if (mounted) {
          showHonooToast(context, message: 'Hai già una richiesta in corso.');
        }
        return;
      }

      final user = SupabaseProvider.client.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        showHonooToast(context,
            message: 'Accedi prima per richiedere una casa.');
        return;
      }

      final String email = user.email ?? '';
      final admin = AdminService();
      final bool isAdmin = await admin.isCurrentUserAdmin();

      if (!mounted) return;

      if (!isAdmin) {
        // Utente normale: prova a registrare la richiesta su house_invites (se consentito da RLS)
        try {
          await _campanelliController.createPendingHouseRequest(
            userId: user.id,
            email: email,
          );
        } catch (_) {
          // ignora: in ambienti dove RLS non consente l'insert, continua con solo feedback
        }

        // Feedback locale
        if (!mounted) {
          _campanelliController.endInviteRequest();
          return;
        }
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
                    'Richiesta inviata',
                    style: HonooDialogStyles.title(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    email.isNotEmpty
                        ? '$email ha richiesto una casa sull\'Isola.'
                        : 'Hai richiesto una casa sull\'Isola.',
                    style: HonooDialogStyles.body(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'OK',
                        style: GoogleFonts.libreFranklin(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        return;
      }

      // Admin: mostra dialogo con Non ora / Invita
      final bool? invite = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (_) => HonooDialogShell(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Richiesta ricevuta',
                  style: HonooDialogStyles.title(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  email.isNotEmpty
                      ? '$email ha richiesto una casa sull\'Isola.'
                      : 'Un utente ha richiesto una casa sull\'Isola.',
                  style: HonooDialogStyles.body(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          'Non ora',
                          style: HonooDialogStyles.secondaryAction(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Invita',
                          style: GoogleFonts.libreFranklin(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      if (invite == true) {
        if (!mounted) return;
        try {
          final adminUid = user.id;
          if (email.isEmpty) {
            showHonooToast(context, message: 'Email utente non disponibile.');
            return;
          }
          final ok =
              await admin.inviteByEmailOnly(adminUid: adminUid, email: email);
          if (!mounted) return;
          showHonooToast(
            context,
            message:
                ok ? 'Invito inviato.' : 'Invito già presente o non inviabile.',
          );
        } catch (e) {
          if (!mounted) return;
          showHonooToast(context, message: 'Errore invito: $e');
        }
      }
    } finally {
      _campanelliController.endInviteRequest();
    }
  }

  List<_CampanelloPageData> _buildCampanelloPages(
    List<_CampanelloEntry> campanelli,
  ) {
    final pages = <_CampanelloPageData>[
      _CampanelloPageData.intro(Utility().campanelliText),
      for (final campanello in campanelli)
        _CampanelloPageData.campanello(campanello.campanello),
    ];

    // Se l'utente non ha ancora una casa/campanello e non ha inviti pendenti, aggiungi pagina CTA
    if (!_hasOwnHouse && !_hasPendingOrAcceptedInvite) {
      pages.add(
        _CampanelloPageData.intro(
          'Vuoi\n anche tu\n una casa\n sull\'Isola?\n\nClicca qui',
        ),
      );
    }

    return pages;
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

  Future<void> _loadUserEntries() async {
    if (_isLoadingUserEntries) return;
    final user = SupabaseProvider.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoadingUserEntries = true);
    try {
      final loadState = await _campanelliController.load(user.id);
      if (loadState.error != null) throw loadState.error!;
      final List<String> ownedHinooIds = loadState.ownedHinooIds;
      if (loadState.entries.isEmpty) {
        if (mounted) {
          setState(() {
            _userEntries = const [];
            _ownedHinooIds = const [];
          });
        }
        return;
      }

      final shareRows = loadState.shareRows;

      for (final row in shareRows) {
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

      final entries = loadState.entries.map((entry) {
        final casaId = 'casa_${entry.hinooId}';
        return _CampanelloEntry(
          campanello: CampanelloData(
            id: 'campanello_${entry.hinooId}',
            campanelloHinooId: entry.hinooId,
            ownerId: entry.ownerId,
            backgroundImage: _campanelloBackgroundProvider(
              entry.campanelloBackgroundUrl,
            ),
            text: entry.text,
            linkedHouseId: casaId,
          ),
          casa: CasaData(
            id: casaId,
            backgroundImage: _houseBackgroundProvider(
              entry.houseImageUrl,
              entry.campanelloBackgroundUrl,
            ),
            bgTransform: entry.bgTransform,
            bgScale: entry.bgScale,
            bgOffsetX: entry.bgOffsetX,
            bgOffsetY: entry.bgOffsetY,
          ),
        );
      }).toList(growable: false);

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
      // Verifica inviti pendenti/accettati per nascondere CTA se già invitato
      try {
        await _campanelliController.refreshHouseInviteState(user.id);
        if (mounted) setState(() {});
      } catch (_) {}
      _subscribeOwnerAccessChannel();
      await _campanelliController.startPendingKnockRefresh(
        ownedHinooIds: ownedHinooIds,
        onChanged: () {
          if (mounted) setState(() {});
        },
      );
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
      _campanelliController.startOwnerRealtime(
        userId: user.id,
        ownedHinooIds: _ownedHinooIds,
        onPendingKnock: (_) {
          if (!mounted) return;
          setState(() {});
          final now = DateTime.now();
          if (_lastKnockToastAt == null ||
              now.difference(_lastKnockToastAt!) > const Duration(seconds: 3)) {
            _lastKnockToastAt = now;
            showHonooToast(
              context,
              message: 'Qualcuno ha bussato alla tua casa',
            );
          }
        },
        onPendingRemoved: () {
          if (mounted) setState(() {});
        },
      );
    } catch (_) {
      // In test or when Realtime not available, safely ignore
    }
  }

  void _subscribeVisitorAccessChannel() {
    try {
      final user = SupabaseProvider.client.auth.currentUser;
      if (user == null) return;
      _campanelliController.startVisitorRealtime(
        userId: user.id,
        onAccessGranted: (tag) async {
          if (!mounted) return;
          showHonooToast(context, message: 'La casa è stata aperta');
          try {
            HapticFeedback.lightImpact();
          } catch (_) {}
          await _goToCampanelloByTag(tag);
          await _hintCampanelloBounce();
          final entry = _entryForTag(tag);
          if (entry != null && mounted) {
            setState(() => _unlockedCampanelli.add(entry.campanello.id));
          }
        },
      );
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
      await _campanelloPageController.animateTo(target,
          duration: _kBounceIn, curve: _kCurve);
      await _campanelloPageController.animateTo(start,
          duration: _kBounceOut, curve: _kCurve);
    } catch (_) {}
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

  Future<void> _approvePendingKnock(
    PendingKnock knock,
    _CampanelloEntry entry, {
    HinooDraft? draft,
    Honoo? honoo,
  }) async {
    await _showBusyOverlay('Apro la casa...');
    try {
      final Set<_CasaShareMode>? modes = await _showOwnerMultiShareDialog();
      if (modes == null || modes.isEmpty || !mounted) return;
      final user = SupabaseProvider.client.auth.currentUser;
      final campanelloHinooId = entry.campanello.campanelloHinooId;
      if (user == null || campanelloHinooId == null) return;
      try {
        await _campanelliController.approvePendingKnock(
          knockId: knock.id,
          ownerId: user.id,
          campanelloHinooId: campanelloHinooId,
          shareModes: modes.map((mode) => mode.dbValue).toList(growable: false),
        );
        if (mounted) {
          setState(() {
            _shareModesByCampanello[_shareKeyFor(entry.campanello)] = modes;
          });
        }
      } catch (e) {
        debugPrint('house_access grant error: $e');
        if (mounted) {
          showHonooToast(context, message: 'Operazione non riuscita. Ritenta.');
        }
        return;
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
    setState(() {});
    showHonooToast(context, message: 'Casa aperta.');
    // Light haptic on owner approval as further confirmation
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  Future<void> _openPendingKnock(PendingKnock knock) async {
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
      final draft =
          await _campanelliController.fetchPendingHinoo(knock.hinooId!);
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
      final honoo =
          await _campanelliController.fetchPendingHonoo(knock.honooId!);
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
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
    final List<PendingKnock> sorted = List<PendingKnock>.from(_pendingKnocks)
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
                                      style: HonooDialogStyles.tertiaryAction(),
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
    _pageController.dispose();
    _campanelloPageController.dispose();
    _campanelliController.dispose();
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
          final double targetMaxWidth =
              layoutMode == ResponsiveLayoutMode.mobile
                  ? maxWidth
                  : ResponsiveLayout.contentMaxWidth(maxWidth);

          final double footerIconSize =
              ResponsiveLayout.footerIconSizeForMode(layoutMode);
          final double footerGap =
              ResponsiveLayout.footerGapForMode(layoutMode);
          final bool isMobile = layoutMode == ResponsiveLayoutMode.mobile;
          final double footerBottomPadding =
              ResponsiveLayout.footerBottomPaddingForMode(layoutMode) +
                  (isMobile ? 0 : 12);
          final double safeBottom = MediaQuery.of(context).viewPadding.bottom;
          final double footerSpacing = footerBottomPadding + safeBottom;
          final double footerTopSpacing = footerSpacing / 2;
          final double footerBottomSpacing = footerSpacing - footerTopSpacing;

          final double footerReserved =
              footerIconSize + footerTopSpacing + footerBottomSpacing;
          final double availableHeight =
              (maxHeight - footerReserved).clamp(0.0, double.infinity);
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
          final CampanelloData? activeCampanello =
              showCampanello ? campanelli[casaIndex].campanello : null;
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
          final ScrollPhysics pagePhysics =
              const PageScrollPhysics().applyTo(const BouncingScrollPhysics());
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
                                  onExit: (_) => _isHoveringCampanelli = false,
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
                                      behavior: ScrollConfiguration.of(context)
                                          .copyWith(
                                        dragDevices: {
                                          PointerDeviceKind.touch,
                                          PointerDeviceKind.mouse,
                                          PointerDeviceKind.stylus,
                                          PointerDeviceKind.trackpad,
                                        },
                                      ),
                                      child: () {
                                        final pvViewport = SizedBox(
                                          width: canvasSize.width,
                                          height: canvasSize.height,
                                          child: PageView.builder(
                                            controller:
                                                _campanelloPageController,
                                            scrollDirection: Axis.horizontal,
                                            physics: pagePhysics,
                                            itemCount: campanelloPages.length,
                                            onPageChanged: (index) {
                                              setState(() =>
                                                  _campanelloIndex = index);
                                            },
                                            itemBuilder: (context, pageIndex) {
                                              return _CampanelloCard(
                                                data:
                                                    campanelloPages[pageIndex],
                                                width: canvasSize.width,
                                                height: canvasSize.height,
                                                onRequestTap:
                                                    _handleInviteRequestTap,
                                              );
                                            },
                                          ),
                                        );
                                        final bool isDesktop = layoutMode ==
                                                ResponsiveLayoutMode.desktop ||
                                            layoutMode ==
                                                ResponsiveLayoutMode
                                                    .wideDesktop ||
                                            layoutMode ==
                                                ResponsiveLayoutMode
                                                    .largeDesktop;
                                        if (!isDesktop ||
                                            campanelloPages.length <= 1) {
                                          return pvViewport;
                                        }
                                        // Su desktop, allarga l'area esterna per ospitare le frecce
                                        const double arrowGutter = 160;
                                        return SizedBox(
                                          width: canvasSize.width + arrowGutter,
                                          height: canvasSize.height,
                                          child: DesktopCarouselArrows(
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
                                            child: Center(child: pvViewport),
                                          ),
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
          final double footerGap =
              ResponsiveLayout.footerGapForMode(layoutMode);
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
          final double footerGap =
              ResponsiveLayout.footerGapForMode(layoutMode);
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
    this.onRequestTap,
  });

  final _CampanelloPageData data;
  final double width;
  final double height;
  final VoidCallback? onRequestTap;

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
        child: _buildText(textStyle),
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

  Widget _buildText(TextStyle textStyle) {
    // Rende "Clicca qui" sottolineato e cliccabile se presente
    final String raw = data.text;
    final idx = raw.toLowerCase().lastIndexOf('clicca qui');
    if (idx < 0 || onRequestTap == null) {
      return Text(raw, style: textStyle, textAlign: TextAlign.center);
    }

    final String before = raw.substring(0, idx);
    final String link = raw.substring(idx, idx + 'clicca qui'.length);
    final String after = raw.substring(idx + 'clicca qui'.length);
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: textStyle,
        children: [
          TextSpan(text: before),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: InkWell(
              onTap: onRequestTap,
              child: Text(
                link,
                style: textStyle.copyWith(
                  decoration: TextDecoration.underline,
                  decorationColor: textStyle.color,
                  decorationThickness: 2.5,
                ),
              ),
            ),
          ),
          TextSpan(text: after),
        ],
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
                      backgroundColor: _selected.contains(mode)
                          ? Colors.white
                          : Colors.transparent,
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
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.black),
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
                    final nav = Navigator.of(context);
                    setState(() => _saving = true);
                    try {
                      await widget.onConfirm(_selected);
                      if (!mounted) return;
                      nav.pop(_selected);
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
