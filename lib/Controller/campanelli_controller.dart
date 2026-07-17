import 'package:flutter/foundation.dart';

import '../Entities/campanelli_entry.dart';
import '../Entities/hinoo.dart';
import '../Entities/pending_knock.dart';
import '../Services/campanelli_repository.dart';
import '../Services/campanelli_realtime_service.dart';

@immutable
class CampanelliLoadState {
  const CampanelliLoadState({
    this.entries = const [],
    this.shareRows = const [],
    this.ownedHinooIds = const [],
    this.pendingKnocks = const [],
    this.isLoading = false,
    this.error,
  });

  final List<CampanelliEntry> entries;
  final List<dynamic> shareRows;
  final List<String> ownedHinooIds;
  final List<PendingKnock> pendingKnocks;
  final bool isLoading;
  final Object? error;

  CampanelliLoadState copyWith({
    List<CampanelliEntry>? entries,
    List<dynamic>? shareRows,
    List<String>? ownedHinooIds,
    List<PendingKnock>? pendingKnocks,
    bool? isLoading,
    Object? error,
    bool clearError = false,
  }) {
    return CampanelliLoadState(
      entries: entries ?? this.entries,
      shareRows: shareRows ?? this.shareRows,
      ownedHinooIds: ownedHinooIds ?? this.ownedHinooIds,
      pendingKnocks: pendingKnocks ?? this.pendingKnocks,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class CampanelliController extends ChangeNotifier {
  CampanelliController({
    CampanelliDataRepository? repository,
    CampanelliRealtimeGateway? realtimeGateway,
  })  : _repository = repository ?? CampanelliDataRepository(),
        _configuredRealtimeGateway = realtimeGateway;

  final CampanelliDataRepository _repository;
  final CampanelliRealtimeGateway? _configuredRealtimeGateway;
  CampanelliRealtimeGateway? _defaultRealtimeGateway;
  CampanelliRealtimeGateway get _realtimeGateway =>
      _configuredRealtimeGateway ??
      (_defaultRealtimeGateway ??= SupabaseCampanelliRealtimeGateway());
  CampanelliRealtimeSubscription? _ownerSubscription;
  CampanelliRealtimeSubscription? _visitorSubscription;
  CampanelliLoadState _state = const CampanelliLoadState();

  CampanelliLoadState get state => _state;

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
    required void Function(PendingKnock knock) onPendingKnock,
    required void Function() onPendingRemoved,
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
        if (knock != null) onPendingKnock(knock);
      },
      onDelete: (id) {
        removePendingKnock(id);
        onPendingRemoved();
      },
    );
  }

  void startVisitorRealtime({
    required String userId,
    required void Function(String targetTag) onAccessGranted,
  }) {
    _visitorSubscription?.close();
    _visitorSubscription = _realtimeGateway.subscribeVisitor(
      userId: userId,
      onAccessGranted: onAccessGranted,
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
    stopRealtime();
    super.dispose();
  }
}
