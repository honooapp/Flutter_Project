import 'dart:async';

import 'package:flutter/foundation.dart';

import '../Entities/campanelli_entry.dart';
import '../Entities/campanelli_realtime_event.dart';
import '../Entities/hinoo.dart';
import '../Entities/honoo.dart';
import '../Entities/pending_knock.dart';
import '../Services/campanelli_repository.dart';
import '../Services/campanelli_realtime_service.dart';
import '../Services/house_invite_service.dart';

@immutable
class CampanelliLoadState {
  const CampanelliLoadState({
    this.entries = const [],
    this.shareRows = const [],
    this.ownedHinooIds = const [],
    this.pendingKnocks = const [],
    this.hasOwnHouse = false,
    this.hasPendingOrAcceptedInvite = false,
    this.isInviteRequestBusy = false,
    this.isLoading = false,
    this.error,
  });

  final List<CampanelliEntry> entries;
  final List<dynamic> shareRows;
  final List<String> ownedHinooIds;
  final List<PendingKnock> pendingKnocks;
  final bool hasOwnHouse;
  final bool hasPendingOrAcceptedInvite;
  final bool isInviteRequestBusy;
  final bool isLoading;
  final Object? error;

  CampanelliLoadState copyWith({
    List<CampanelliEntry>? entries,
    List<dynamic>? shareRows,
    List<String>? ownedHinooIds,
    List<PendingKnock>? pendingKnocks,
    bool? hasOwnHouse,
    bool? hasPendingOrAcceptedInvite,
    bool? isInviteRequestBusy,
    bool? isLoading,
    Object? error,
    bool clearError = false,
  }) {
    return CampanelliLoadState(
      entries: entries ?? this.entries,
      shareRows: shareRows ?? this.shareRows,
      ownedHinooIds: ownedHinooIds ?? this.ownedHinooIds,
      pendingKnocks: pendingKnocks ?? this.pendingKnocks,
      hasOwnHouse: hasOwnHouse ?? this.hasOwnHouse,
      hasPendingOrAcceptedInvite:
          hasPendingOrAcceptedInvite ?? this.hasPendingOrAcceptedInvite,
      isInviteRequestBusy: isInviteRequestBusy ?? this.isInviteRequestBusy,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class CampanelliController extends ChangeNotifier {
  CampanelliController({
    CampanelliDataRepository? repository,
    CampanelliRealtimeGateway? realtimeGateway,
    HouseInviteService? houseInviteService,
  })  : _repository = repository ?? CampanelliDataRepository(),
        _configuredRealtimeGateway = realtimeGateway,
        _configuredHouseInviteService = houseInviteService;

  final CampanelliDataRepository _repository;
  final CampanelliRealtimeGateway? _configuredRealtimeGateway;
  final HouseInviteService? _configuredHouseInviteService;
  HouseInviteService? _defaultHouseInviteService;
  HouseInviteService get _houseInviteService =>
      _configuredHouseInviteService ??
      (_defaultHouseInviteService ??= HouseInviteService());
  CampanelliRealtimeGateway? _defaultRealtimeGateway;
  CampanelliRealtimeGateway get _realtimeGateway =>
      _configuredRealtimeGateway ??
      (_defaultRealtimeGateway ??= SupabaseCampanelliRealtimeGateway());
  CampanelliRealtimeSubscription? _ownerSubscription;
  CampanelliRealtimeSubscription? _visitorSubscription;
  Timer? _pendingKnockRefreshTimer;
  bool _isRefreshingPendingKnocks = false;
  CampanelliLoadState _state = const CampanelliLoadState();
  final StreamController<CampanelliRealtimeEvent> _realtimeEvents =
      StreamController<CampanelliRealtimeEvent>.broadcast();

  CampanelliLoadState get state => _state;
  Stream<CampanelliRealtimeEvent> get realtimeEvents => _realtimeEvents.stream;

  Future<CampanelliLoadState> load(String userId) async {
    if (_state.isLoading) return _state;
    _publish(_state.copyWith(isLoading: true, clearError: true));

    try {
      final houseRows = await _repository.fetchHouseRows();
      final ownerByHinooId = <String, String>{};
      final houseByHinooId = <String, Map<String, dynamic>>{};
      final hinooIds = <String>[];
      final ownedHinooIds = <String>[];
      for (final row in houseRows) {
        if (row is! Map) continue;
        final hinooId = row['campanello_hinoo_id']?.toString() ?? '';
        final ownerId = row['owner_id']?.toString() ?? '';
        if (hinooId.isEmpty || ownerId.isEmpty) continue;
        ownerByHinooId[hinooId] = ownerId;
        houseByHinooId[hinooId] = Map<String, dynamic>.from(row);
        hinooIds.add(hinooId);
        if (ownerId == userId) ownedHinooIds.add(hinooId);
      }

      final shareRows = await _repository.fetchShareSettingsRows(hinooIds);
      final hinooRows = await _repository.fetchHinooRows(hinooIds);
      final entries = <CampanelliEntry>[];
      for (final row in hinooRows) {
        if (row is! Map) continue;
        final id = row['id']?.toString() ?? '';
        final pages = row['pages'];
        if (id.isEmpty || pages is! List || pages.isEmpty) continue;
        final firstPage = pages.first;
        if (firstPage is! Map) continue;
        final ownerId = ownerByHinooId[id];
        if (ownerId == null) continue;
        final slide = HinooSlide.fromJson(firstPage.cast<String, dynamic>());
        final text = slide.text.trim();
        if (text.isEmpty) continue;
        final houseRow = houseByHinooId[id] ?? const <String, dynamic>{};
        entries.add(CampanelliEntry(
          hinooId: id,
          ownerId: ownerId,
          text: text,
          campanelloBackgroundUrl: slide.backgroundImage,
          houseImageUrl: houseRow['house_image_url']?.toString(),
          bgTransform: _parseTransform(houseRow['bg_transform']),
          bgScale: slide.bgScale,
          bgOffsetX: slide.bgOffsetX,
          bgOffsetY: slide.bgOffsetY,
        ));
      }
      _publish(CampanelliLoadState(
        entries: List<CampanelliEntry>.unmodifiable(entries),
        shareRows: List<dynamic>.unmodifiable(shareRows),
        ownedHinooIds: List<String>.unmodifiable(ownedHinooIds),
        pendingKnocks: _state.pendingKnocks,
        hasOwnHouse: ownedHinooIds.isNotEmpty,
        hasPendingOrAcceptedInvite: _state.hasPendingOrAcceptedInvite,
        isInviteRequestBusy: _state.isInviteRequestBusy,
      ));
    } catch (error) {
      _publish(CampanelliLoadState(error: error));
    }
    return _state;
  }

  Future<List<PendingKnock>> loadPendingKnocks(
    List<String> ownedHinooIds,
  ) async {
    if (ownedHinooIds.isEmpty) {
      _replacePendingKnocks(const []);
      return const [];
    }
    final rows = await _repository.fetchPendingKnockRows(ownedHinooIds);
    final knocks = rows
        .whereType<Map>()
        .map(_pendingKnockFromRow)
        .whereType<PendingKnock>()
        .toList(growable: false);
    _replacePendingKnocks(knocks);
    return _state.pendingKnocks;
  }

  Future<HinooDraft?> fetchPendingHinoo(String hinooId) async {
    final row = await _repository.fetchHinooForKnock(hinooId);
    if (row == null || row['pages'] is! List) return null;
    final pages = row['pages'] as List;
    return HinooDraft(
      pages: pages
          .whereType<Map<String, dynamic>>()
          .map(HinooSlide.fromJson)
          .toList(growable: false),
      type: HinooType.answer,
      recipientTag: row['recipient_tag'] as String?,
    );
  }

  Future<Honoo?> fetchPendingHonoo(String honooId) async {
    final row = await _repository.fetchHonooForKnock(honooId);
    if (row == null) return null;
    return Honoo.fromMap(row);
  }

  Future<void> approvePendingKnock({
    required String knockId,
    required String ownerId,
    required String campanelloHinooId,
    required List<String> shareModes,
    DateTime? approvedAt,
  }) async {
    final timestamp = approvedAt ?? DateTime.now();
    await _repository.saveShareModes(
      ownerId: ownerId,
      campanelloHinooId: campanelloHinooId,
      modes: shareModes,
      updatedAt: timestamp,
    );
    await _repository.grantHouseAccess(
      knockId: knockId,
      grantedAt: timestamp,
    );
    removePendingKnock(knockId);
  }

  Future<bool> refreshHouseInviteState(String userId) async {
    final hasInvite =
        await _houseInviteService.hasPendingOrAcceptedInvite(userId);
    _publish(_state.copyWith(hasPendingOrAcceptedInvite: hasInvite));
    return hasInvite;
  }

  bool beginInviteRequest() {
    if (_state.isInviteRequestBusy) return false;
    _publish(_state.copyWith(isInviteRequestBusy: true));
    return true;
  }

  void endInviteRequest() {
    if (!_state.isInviteRequestBusy) return;
    _publish(_state.copyWith(isInviteRequestBusy: false));
  }

  Future<void> createPendingHouseRequest({
    required String userId,
    required String email,
    DateTime? createdAt,
  }) async {
    await _houseInviteService.createPendingRequest(
      userId: userId,
      email: email,
      createdAt: createdAt ?? DateTime.now(),
    );
    _publish(_state.copyWith(hasPendingOrAcceptedInvite: true));
  }

  Future<void> startPendingKnockRefresh({
    required List<String> ownedHinooIds,
    required void Function() onChanged,
    Duration interval = const Duration(seconds: 60),
  }) async {
    _pendingKnockRefreshTimer?.cancel();
    final ids = List<String>.unmodifiable(ownedHinooIds);
    await refreshPendingKnocks(ids, onChanged: onChanged);
    _pendingKnockRefreshTimer = Timer.periodic(
      interval,
      (_) => unawaited(refreshPendingKnocks(ids, onChanged: onChanged)),
    );
  }

  Future<bool> refreshPendingKnocks(
    List<String> ownedHinooIds, {
    required void Function() onChanged,
  }) async {
    if (_isRefreshingPendingKnocks || ownedHinooIds.isEmpty) return false;
    _isRefreshingPendingKnocks = true;
    try {
      await loadPendingKnocks(ownedHinooIds);
      onChanged();
      return true;
    } catch (_) {
      return false;
    } finally {
      _isRefreshingPendingKnocks = false;
    }
  }

  void stopPendingKnockRefresh() {
    _pendingKnockRefreshTimer?.cancel();
    _pendingKnockRefreshTimer = null;
  }

  bool addPendingKnockRow(Map<dynamic, dynamic> row) {
    final knock = _pendingKnockFromRow(row);
    if (knock == null) return false;
    final updated = <PendingKnock>[
      ..._state.pendingKnocks.where((item) => item.id != knock.id),
      knock,
    ];
    _replacePendingKnocks(updated);
    return true;
  }

  void removePendingKnock(String id) {
    _replacePendingKnocks(
      _state.pendingKnocks.where((item) => item.id != id).toList(),
    );
  }

  Set<String> get pendingKnockTags => Set<String>.unmodifiable(
        _state.pendingKnocks.map((knock) => knock.targetTag),
      );

  void startOwnerRealtime({
    required String userId,
    required List<String> ownedHinooIds,
  }) {
    _ownerSubscription?.close();
    _ownerSubscription = _realtimeGateway.subscribeOwner(
      userId: userId,
      ownedHinooIds: ownedHinooIds,
      onPendingInsert: (row) {
        if (!addPendingKnockRow(row)) return;
        final id = row['id']?.toString() ?? '';
        PendingKnock? knock;
        for (final item in _state.pendingKnocks) {
          if (item.id == id) {
            knock = item;
            break;
          }
        }
        if (knock != null) {
          _realtimeEvents.add(CampanelliPendingKnockReceived(knock));
        }
      },
      onDelete: (id) {
        removePendingKnock(id);
        _realtimeEvents.add(CampanelliPendingKnockRemoved(id));
      },
    );
  }

  void startVisitorRealtime({
    required String userId,
  }) {
    _visitorSubscription?.close();
    _visitorSubscription = _realtimeGateway.subscribeVisitor(
      userId: userId,
      onAccessGranted: (targetTag) {
        _realtimeEvents.add(CampanelliAccessGranted(targetTag));
      },
    );
  }

  void stopRealtime() {
    _ownerSubscription?.close();
    _visitorSubscription?.close();
    _ownerSubscription = null;
    _visitorSubscription = null;
  }

  PendingKnock? _pendingKnockFromRow(Map<dynamic, dynamic> row) {
    final id = row['id']?.toString() ?? '';
    final targetTag = row['target_house_tag']?.toString() ?? '';
    if (id.isEmpty || targetTag.isEmpty) return null;
    final rawCreatedAt = row['created_at']?.toString() ?? '';
    return PendingKnock(
      id: id,
      targetTag: targetTag,
      createdAt: DateTime.tryParse(rawCreatedAt) ?? DateTime.now(),
      hinooId: row['hinoo_id']?.toString(),
      honooId: row['honoo_id']?.toString(),
    );
  }

  void _replacePendingKnocks(Iterable<PendingKnock> knocks) {
    _publish(_state.copyWith(
      pendingKnocks: List<PendingKnock>.unmodifiable(knocks),
    ));
  }

  static List<double>? _parseTransform(dynamic raw) {
    if (raw is! List) return null;
    try {
      return List<double>.unmodifiable(
        raw.map((value) => (value as num).toDouble()),
      );
    } catch (_) {
      return null;
    }
  }

  void _publish(CampanelliLoadState value) {
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    stopPendingKnockRefresh();
    stopRealtime();
    _realtimeEvents.close();
    super.dispose();
  }
}
