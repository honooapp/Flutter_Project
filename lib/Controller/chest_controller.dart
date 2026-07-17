import 'dart:async';

import 'package:flutter/foundation.dart';

import '../Entities/chest_item.dart';
import '../Entities/hinoo.dart';
import '../Entities/hinoo_thread_entry.dart';
import '../Services/chest_repository.dart';
import '../Services/chest_realtime_service.dart';

class ChestState {
  ChestState({
    List<ChestHinooItem> hinoo = const [],
    Map<String, DateTime> honooLatestReplies = const {},
    Map<String, DateTime> hinooLatestReplies = const {},
    Map<String, List<HinooThreadEntry>> hinooRepliesByRoot = const {},
    this.isHinooLoading = true,
    this.isReplyLoading = false,
    this.error,
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
  final Object? error;
}

class ChestController extends ValueNotifier<ChestState> {
  ChestController({
    required ChestRepository repository,
    ChestRealtimeGateway? realtimeGateway,
  })  : _realtimeGateway = realtimeGateway ?? SupabaseChestRealtimeGateway(),
        _repository = repository,
        super(ChestState());

  final ChestRepository _repository;
  final ChestRealtimeGateway _realtimeGateway;
  ChestRealtimeSubscription? _realtimeSubscription;
  Timer? _periodicRefreshTimer;
  Timer? _realtimeDebounce;
  String? _activeUserId;
  bool _isRefreshingReplies = false;

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
    if (_isRefreshingReplies) return;
    _isRefreshingReplies = true;
    try {
      await loadReplies(userId);
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
    );

    try {
      final rows = await _repository.fetchHinooRows(userId);
      final hinoo = rows
          .whereType<Map>()
          .map(ChestHinooItem.fromDatabaseRow)
          .whereType<ChestHinooItem>()
          .toList(growable: false);
      value = ChestState(
        hinoo: List.unmodifiable(hinoo),
        honooLatestReplies: value.honooLatestReplies,
        hinooLatestReplies: value.hinooLatestReplies,
        hinooRepliesByRoot: value.hinooRepliesByRoot,
        isHinooLoading: false,
        isReplyLoading: value.isReplyLoading,
      );
    } catch (error) {
      value = ChestState(
        hinoo: value.hinoo,
        honooLatestReplies: value.honooLatestReplies,
        hinooLatestReplies: value.hinooLatestReplies,
        hinooRepliesByRoot: value.hinooRepliesByRoot,
        isHinooLoading: false,
        isReplyLoading: value.isReplyLoading,
        error: error,
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
    );

    try {
      final honooLatest = <String, DateTime>{};
      final honooRows = await _repository.fetchHonooReplyRows(userId);
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
      final rows = await _repository.fetchHinooReplyRows(userId, rootIds);
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
      );
    } catch (error) {
      value = ChestState(
        hinoo: value.hinoo,
        honooLatestReplies: value.honooLatestReplies,
        hinooLatestReplies: value.hinooLatestReplies,
        hinooRepliesByRoot: value.hinooRepliesByRoot,
        isHinooLoading: value.isHinooLoading,
        isReplyLoading: false,
        error: error,
      );
    }
  }
}
