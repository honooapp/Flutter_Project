import 'dart:async';

import 'package:flutter/foundation.dart';

import '../Entities/chest_item.dart';
import '../Entities/hinoo.dart';
import '../Entities/hinoo_thread_entry.dart';
import '../Services/chest_repository.dart';
import '../Services/chest_realtime_service.dart';
import '../Services/hinoo_service.dart';
import '../Services/reliability_policy.dart';

class ChestState {
  ChestState({
    List<ChestHinooItem> hinoo = const [],
    Map<String, DateTime> honooLatestReplies = const {},
    Map<String, DateTime> hinooLatestReplies = const {},
    Map<String, List<HinooThreadEntry>> hinooRepliesByRoot = const {},
    this.isHinooLoading = true,
    this.isReplyLoading = false,
    this.hinooError,
    this.replyError,
  })  : hinoo = List.unmodifiable(hinoo),
        honooLatestReplies = Map.unmodifiable(honooLatestReplies),
        hinooLatestReplies = Map.unmodifiable(hinooLatestReplies),
        hinooRepliesByRoot = Map.unmodifiable(
          hinooRepliesByRoot.map(
            (key, value) => MapEntry(key, List.unmodifiable(value)),
          ),
        );

  final List<ChestHinooItem> hinoo;
  final Map<String, DateTime> honooLatestReplies;
  final Map<String, DateTime> hinooLatestReplies;
  final Map<String, List<HinooThreadEntry>> hinooRepliesByRoot;
  final bool isHinooLoading;
  final bool isReplyLoading;
  final Object? hinooError;
  final Object? replyError;
  Object? get error => hinooError ?? replyError;
}

class ChestController extends ValueNotifier<ChestState> {
  ChestController({
    required ChestRepository repository,
    ChestRealtimeGateway? realtimeGateway,
    ReliabilityPolicy reliabilityPolicy = const ReliabilityPolicy(),
  })  : _realtimeGateway = realtimeGateway ?? SupabaseChestRealtimeGateway(),
        _repository = repository,
        _reliability = reliabilityPolicy,
        super(ChestState());

  final ChestRepository _repository;
  final ChestRealtimeGateway _realtimeGateway;
  final ReliabilityPolicy _reliability;
  ChestRealtimeSubscription? _realtimeSubscription;
  Timer? _periodicRefreshTimer;
  Timer? _realtimeDebounce;
  String? _activeUserId;
  bool _isRefreshingReplies = false;
  bool _refreshPending = false;

  void startRealtime(
    String userId, {
    Duration refreshInterval = const Duration(seconds: 60),
  }) {
    stopRealtime();
    _activeUserId = userId;
    try {
      _realtimeSubscription = _realtimeGateway.subscribe(
        userId: userId,
        onChange: _scheduleRealtimeRefresh,
      );
    } catch (_) {
      _realtimeSubscription = null;
    }
    _periodicRefreshTimer = Timer.periodic(
      refreshInterval,
      (_) => refreshReplies(userId),
    );
  }

  void _scheduleRealtimeRefresh() {
    _realtimeDebounce?.cancel();
    _realtimeDebounce = Timer(const Duration(milliseconds: 250), () {
      final userId = _activeUserId;
      if (userId != null) refreshReplies(userId);
    });
  }

  Future<void> refreshReplies(String userId) async {
    if (_isRefreshingReplies) {
      _refreshPending = true;
      return;
    }
    _isRefreshingReplies = true;
    try {
      do {
        _refreshPending = false;
        await loadReplies(userId);
      } while (_refreshPending);
    } finally {
      _isRefreshingReplies = false;
    }
  }

  void stopRealtime() {
    _periodicRefreshTimer?.cancel();
    _periodicRefreshTimer = null;
    _realtimeDebounce?.cancel();
    _realtimeDebounce = null;
    _realtimeSubscription?.close();
    _realtimeSubscription = null;
    _activeUserId = null;
  }

  @override
  void dispose() {
    stopRealtime();
    super.dispose();
  }

  void completeWithoutUser() {
    value = ChestState(
      hinoo: value.hinoo,
      honooLatestReplies: value.honooLatestReplies,
      hinooLatestReplies: value.hinooLatestReplies,
      hinooRepliesByRoot: value.hinooRepliesByRoot,
      isHinooLoading: false,
      isReplyLoading: false,
      hinooError: value.hinooError,
      replyError: value.replyError,
    );
  }

  void removeHinoo(String id) {
    value = ChestState(
      hinoo: value.hinoo.where((item) => item.id != id).toList(),
      honooLatestReplies: value.honooLatestReplies,
      hinooLatestReplies: value.hinooLatestReplies,
      hinooRepliesByRoot: value.hinooRepliesByRoot,
      isHinooLoading: value.isHinooLoading,
      isReplyLoading: value.isReplyLoading,
      hinooError: value.hinooError,
      replyError: value.replyError,
    );
  }

  void markHinooOnMoon(String id) {
    value = ChestState(
      hinoo: value.hinoo
          .map(
            (item) => item.id == id
                ? ChestHinooItem(
                    id: item.id,
                    draft: item.draft,
                    createdAt: item.createdAt,
                    isFromMoonSaved: item.isFromMoonSaved,
                    ownerId: item.ownerId,
                    isOnMoon: true,
                    conversationId: item.conversationId,
                  )
                : item,
          )
          .toList(),
      honooLatestReplies: value.honooLatestReplies,
      hinooLatestReplies: value.hinooLatestReplies,
      hinooRepliesByRoot: value.hinooRepliesByRoot,
      isHinooLoading: value.isHinooLoading,
      isReplyLoading: value.isReplyLoading,
      hinooError: value.hinooError,
      replyError: value.replyError,
    );
  }

  Future<void> loadHinoo(String userId) async {
    value = ChestState(
      hinoo: value.hinoo,
      honooLatestReplies: value.honooLatestReplies,
      hinooLatestReplies: value.hinooLatestReplies,
      hinooRepliesByRoot: value.hinooRepliesByRoot,
      isHinooLoading: true,
      isReplyLoading: value.isReplyLoading,
      replyError: value.replyError,
    );

    try {
      final rows = await _reliability.read<List<dynamic>>(
        () => _repository.fetchHinooRows(userId),
      );
      Set<String> moonFingerprints = const {};
      try {
        moonFingerprints = await _reliability.read<Set<String>>(
          () => _repository.fetchHinooMoonFingerprints(userId),
        );
      } catch (_) {
        // Il contenuto dello Scrigno resta utilizzabile anche se il controllo
        // dello stato Luna non è temporaneamente disponibile.
      }
      final hinoo = rows
          .whereType<Map>()
          .map(ChestHinooItem.fromDatabaseRow)
          .whereType<ChestHinooItem>()
          .map((item) {
        final fingerprint = HinooService.fingerprint(
          item.draft.copyWith(type: HinooType.moon),
        );
        if (!moonFingerprints.contains(fingerprint)) return item;
        return ChestHinooItem(
          id: item.id,
          draft: item.draft,
          createdAt: item.createdAt,
          isFromMoonSaved: item.isFromMoonSaved,
          ownerId: item.ownerId,
          isOnMoon: true,
          conversationId: item.conversationId,
        );
      }).toList(growable: false);
      value = ChestState(
        hinoo: List.unmodifiable(hinoo),
        honooLatestReplies: value.honooLatestReplies,
        hinooLatestReplies: value.hinooLatestReplies,
        hinooRepliesByRoot: value.hinooRepliesByRoot,
        isHinooLoading: false,
        isReplyLoading: value.isReplyLoading,
        replyError: value.replyError,
      );
    } catch (error) {
      value = ChestState(
        hinoo: value.hinoo,
        honooLatestReplies: value.honooLatestReplies,
        hinooLatestReplies: value.hinooLatestReplies,
        hinooRepliesByRoot: value.hinooRepliesByRoot,
        isHinooLoading: false,
        isReplyLoading: value.isReplyLoading,
        hinooError: error,
        replyError: value.replyError,
      );
    }
  }

  Future<void> loadReplies(String userId) async {
    value = ChestState(
      hinoo: value.hinoo,
      honooLatestReplies: value.honooLatestReplies,
      hinooLatestReplies: value.hinooLatestReplies,
      hinooRepliesByRoot: value.hinooRepliesByRoot,
      isHinooLoading: value.isHinooLoading,
      isReplyLoading: true,
      hinooError: value.hinooError,
    );

    try {
      final honooLatest = <String, DateTime>{};
      final honooRows = await _reliability.refresh<List<dynamic>>(
        () => _repository.fetchHonooReplyRows(userId),
      );
      final seenHonooKeys = <String>{};
      for (final row in honooRows.whereType<Map>()) {
        final rootId = row['reply_to']?.toString() ?? '';
        if (rootId.isEmpty) continue;
        final createdRaw = (row['created_at'] ?? '').toString();
        final key = '$rootId|$createdRaw';
        if (!seenHonooKeys.add(key)) continue;
        final created = DateTime.tryParse(createdRaw) ?? DateTime.now();
        final existing = honooLatest[rootId];
        if (existing == null || created.isAfter(existing)) {
          honooLatest[rootId] = created;
        }
      }

      final hinooLatest = <String, DateTime>{};
      final hinooReplies = <String, List<HinooThreadEntry>>{};
      final rootIds = value.hinoo.map((item) => item.id).toList();
      final rows = await _reliability.refresh<List<dynamic>>(
        () => _repository.fetchHinooReplyRows(userId, rootIds),
      );
      final seenHinooIds = <String>{};
      for (final row in rows.whereType<Map>()) {
        final id = row['id']?.toString() ?? '';
        if (id.isNotEmpty && !seenHinooIds.add(id)) continue;
        final rootId = row['reply_to']?.toString() ?? '';
        final pages = row['pages'];
        if (rootId.isEmpty || pages is! List) continue;
        final created =
            DateTime.tryParse((row['created_at'] ?? '').toString()) ??
                DateTime.fromMillisecondsSinceEpoch(0);
        final draft = HinooDraft(
          pages: pages
              .whereType<Map<String, dynamic>>()
              .map(HinooSlide.fromJson)
              .toList(),
          type: HinooType.answer,
          recipientTag: row['recipient_tag'] as String?,
          replyTo: rootId,
        );
        hinooReplies.putIfAbsent(rootId, () => []).add(
              HinooThreadEntry(
                draft: draft,
                authorId: row['user_id']?.toString(),
                isReply: true,
                createdAt: created,
              ),
            );
        final existing = hinooLatest[rootId];
        if (existing == null || created.isAfter(existing)) {
          hinooLatest[rootId] = created;
        }
      }

      value = ChestState(
        hinoo: value.hinoo,
        honooLatestReplies: honooLatest,
        hinooLatestReplies: hinooLatest,
        hinooRepliesByRoot: hinooReplies,
        isHinooLoading: value.isHinooLoading,
        isReplyLoading: false,
        hinooError: value.hinooError,
      );
    } catch (error) {
      value = ChestState(
        hinoo: value.hinoo,
        honooLatestReplies: value.honooLatestReplies,
        hinooLatestReplies: value.hinooLatestReplies,
        hinooRepliesByRoot: value.hinooRepliesByRoot,
        isHinooLoading: value.isHinooLoading,
        isReplyLoading: false,
        hinooError: value.hinooError,
        replyError: error,
      );
    }
  }
}
