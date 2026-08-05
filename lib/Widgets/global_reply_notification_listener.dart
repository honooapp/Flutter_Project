import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Entities/reply_notification_event.dart';
import '../Pages/chest_page.dart';
import '../Services/reply_system_notification.dart';
import '../Services/supabase_provider.dart';
import '../Utility/reply_notification_signal.dart';
import '../Utility/replies_seen_tracker.dart';

class GlobalReplyNotificationListener extends StatefulWidget {
  const GlobalReplyNotificationListener({
    super.key,
    required this.child,
    required this.navigatorKey,
    this.enabled = true,
    this.systemNotification,
    this.replyEventStream,
    this.notificationBatchWindow = const Duration(milliseconds: 180),
  });

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  final bool enabled;
  final ReplySystemNotification? systemNotification;
  @visibleForTesting
  final Stream<ReplyNotificationEvent>? replyEventStream;
  @visibleForTesting
  final Duration notificationBatchWindow;

  @override
  State<GlobalReplyNotificationListener> createState() =>
      _GlobalReplyNotificationListenerState();
}

class _GlobalReplyNotificationListenerState
    extends State<GlobalReplyNotificationListener> {
  late final ReplySystemNotification _systemNotification =
      widget.systemNotification ?? ReplySystemNotification.platform();
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<ReplyNotificationEvent>? _replyEventSubscription;
  RealtimeChannel? _replyChannel;
  Timer? _reconnectTimer;
  Timer? _notificationTimer;
  int _reconnectAttempt = 0;
  int _channelGeneration = 0;
  String? _activeUserId;
  final Set<String> _deliveredEventKeys = <String>{};
  final Map<String, ReplyNotificationEvent> _pendingEvents =
      <String, ReplyNotificationEvent>{};

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _start();
  }

  @override
  void didUpdateWidget(GlobalReplyNotificationListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.enabled && widget.enabled) {
      _start();
    } else if (oldWidget.enabled && !widget.enabled) {
      _stop();
    }
  }

  void _start() {
    final testEvents = widget.replyEventStream;
    if (testEvents != null) {
      _replyEventSubscription ??= testEvents.listen(_handleEvent);
      return;
    }
    _authSubscription ??= SupabaseProvider.client.auth.onAuthStateChange.listen(
      (state) {
        _handleSession(state.session);
      },
    );
    _handleSession(SupabaseProvider.client.auth.currentSession);
  }

  void _handleSession(Session? session) {
    final userId = session?.user.id;
    final accessToken = session?.accessToken;
    if (accessToken != null) {
      SupabaseProvider.client.realtime.setAuth(accessToken);
    }
    if (userId == _activeUserId) {
      if (userId != null && _replyChannel == null) {
        _connectChannels(userId);
      }
      return;
    }
    _closeRealtime(clearUser: false);
    _deliveredEventKeys.clear();
    _activeUserId = userId;
    if (userId == null) return;
    _connectChannels(userId);
  }

  void _connectChannels(String userId) {
    _reconnectTimer?.cancel();
    final generation = ++_channelGeneration;
    try {
      final channel =
          SupabaseProvider.client.channel('reply-events-$userId-$generation')
            ..on(
              RealtimeListenTypes.postgresChanges,
              ChannelFilter(
                event: 'INSERT',
                schema: 'public',
                table: 'honoo',
                filter: 'recipient_tag=eq.$userId',
              ),
              (dynamic payload, [dynamic _]) =>
                  _handlePayload(payload, ReplyNotificationKind.honoo, userId),
            )
            ..on(
              RealtimeListenTypes.postgresChanges,
              ChannelFilter(
                event: 'INSERT',
                schema: 'public',
                table: 'hinoo',
                filter: 'recipient_tag=eq.$userId',
              ),
              (dynamic payload, [dynamic _]) =>
                  _handlePayload(payload, ReplyNotificationKind.hinoo, userId),
            );
      _replyChannel = channel;
      channel.subscribe((status, [error]) {
        if (!mounted || generation != _channelGeneration) return;
        if (status == 'SUBSCRIBED') {
          _reconnectAttempt = 0;
          _reconnectTimer?.cancel();
          unawaited(_catchUpMissedReplies(userId, generation));
          return;
        }
        if (status == 'CHANNEL_ERROR' ||
            status == 'CLOSED' ||
            status == 'TIMED_OUT') {
          _scheduleReconnect(userId);
        }
      });
    } catch (_) {
      _replyChannel = null;
      _scheduleReconnect(userId);
    }
  }

  void _scheduleReconnect(String userId) {
    if (_activeUserId != userId || _reconnectTimer?.isActive == true) return;
    final cappedAttempt = _reconnectAttempt > 5 ? 5 : _reconnectAttempt;
    final seconds = 1 << cappedAttempt;
    _reconnectAttempt += 1;
    _reconnectTimer = Timer(Duration(seconds: seconds), () {
      if (!mounted || _activeUserId != userId) return;
      final staleChannel = _replyChannel;
      _replyChannel = null;
      staleChannel?.unsubscribe();
      _connectChannels(userId);
    });
  }

  void _handlePayload(
    dynamic payload,
    ReplyNotificationKind kind,
    String userId,
  ) {
    final event = ReplyNotificationEvent.fromRealtimePayload(
      payload,
      kind: kind,
      currentUserId: userId,
    );
    if (event == null) return;

    _handleEvent(event);
  }

  void _handleEvent(ReplyNotificationEvent event) {
    final eventKey =
        '${event.recipientId}:${event.kind.name}:${event.replyId ?? event.conversationId}';
    if (!_deliveredEventKeys.add(eventKey)) return;
    if (_deliveredEventKeys.length > 4096) {
      _deliveredEventKeys.remove(_deliveredEventKeys.first);
    }
    _pendingEvents[eventKey] = event;
    _notificationTimer ??= Timer(
      widget.notificationBatchWindow,
      _flushPendingEvents,
    );
  }

  void _flushPendingEvents() {
    _notificationTimer = null;
    if (!mounted || _pendingEvents.isEmpty) return;
    final events = _pendingEvents.values.toList(growable: false);
    _pendingEvents.clear();
    final event = events.last;
    final replyCount = events.length;
    ReplyNotificationSignal.notifyChanged();

    void open() => _openConversation(event);
    _systemNotification.show(
      contentLabel: event.contentLabel,
      conversationId: event.conversationId,
      onTap: open,
      replyCount: replyCount,
    );

    final context = widget.navigatorKey.currentContext;
    if (context == null) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            replyCount == 1
                ? 'Hai ricevuto una risposta al tuo ${event.contentLabel}'
                : 'Hai ricevuto $replyCount nuove risposte',
          ),
          action: SnackBarAction(label: 'Apri', onPressed: open),
        ),
      );
  }

  Future<void> _catchUpMissedReplies(String userId, int generation) async {
    final lastSeen = await RepliesSeenTracker.lastSeen(userId: userId);
    if (!mounted || generation != _channelGeneration || lastSeen == null) {
      return;
    }
    try {
      final since = lastSeen.toUtc().toIso8601String();
      final results = await Future.wait<dynamic>([
        SupabaseProvider.client
            .from('honoo')
            .select(
              'id,destination,reply_to,recipient_tag,created_at,user_id,conversation_id',
            )
            .eq('destination', 'reply')
            .eq('recipient_tag', userId)
            .gt('created_at', since)
            .order('created_at'),
        SupabaseProvider.client
            .from('hinoo')
            .select(
              'id,type,reply_to,recipient_tag,created_at,user_id,conversation_id',
            )
            .eq('type', 'answer')
            .eq('recipient_tag', userId)
            .gt('created_at', since)
            .order('created_at'),
      ]);
      if (!mounted || generation != _channelGeneration) return;
      final pending = <ReplyNotificationEvent>[];
      for (var i = 0; i < results.length; i++) {
        final kind = i == 0
            ? ReplyNotificationKind.honoo
            : ReplyNotificationKind.hinoo;
        for (final row in (results[i] as List).whereType<Map>()) {
          final event = ReplyNotificationEvent.fromRealtimePayload(
            {'eventType': 'INSERT', 'new': row},
            kind: kind,
            currentUserId: userId,
          );
          if (event != null) pending.add(event);
        }
      }
      pending.sort(
        (a, b) => (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );
      for (final event in pending) {
        _handleEvent(event);
      }
    } catch (_) {
      // Il canale realtime resta attivo; il prossimo reconnect ritenterà il catch-up.
    }
  }

  void _openConversation(ReplyNotificationEvent event) {
    widget.navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ChestPage(
          focusReplies: true,
          focusConversationId: event.conversationId,
          focusReplyId: event.replyId,
          highlightLatest: true,
        ),
      ),
    );
  }

  void _closeRealtime({bool clearUser = true}) {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _channelGeneration += 1;
    _replyChannel?.unsubscribe();
    _replyChannel = null;
    _reconnectAttempt = 0;
    if (clearUser) _activeUserId = null;
  }

  void _stop() {
    _notificationTimer?.cancel();
    _notificationTimer = null;
    _pendingEvents.clear();
    _replyEventSubscription?.cancel();
    _replyEventSubscription = null;
    _authSubscription?.cancel();
    _authSubscription = null;
    _closeRealtime();
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
