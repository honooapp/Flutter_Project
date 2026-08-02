import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Entities/reply_notification_event.dart';
import '../Pages/chest_page.dart';
import '../Services/reply_system_notification.dart';
import '../Services/supabase_provider.dart';
import '../Utility/replies_seen_tracker.dart';

class GlobalReplyNotificationListener extends StatefulWidget {
  const GlobalReplyNotificationListener({
    super.key,
    required this.child,
    required this.navigatorKey,
    this.enabled = true,
    this.systemNotification,
    this.replyEventStream,
  });

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  final bool enabled;
  final ReplySystemNotification? systemNotification;
  @visibleForTesting
  final Stream<ReplyNotificationEvent>? replyEventStream;

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
  RealtimeChannel? _honooChannel;
  RealtimeChannel? _hinooChannel;
  String? _activeUserId;
  String? _lastEventKey;
  DateTime? _lastEventAt;

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
      _stopChannels();
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
    if (userId == _activeUserId) return;
    _stopChannels();
    _activeUserId = userId;
    if (userId == null) return;

    final accessToken = session?.accessToken;
    if (accessToken != null) {
      SupabaseProvider.client.realtime.setAuth(accessToken);
    }
    try {
      _honooChannel = SupabaseProvider.client.channel('reply-honoo-$userId')
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
        ..subscribe();
      _hinooChannel = SupabaseProvider.client.channel('reply-hinoo-$userId')
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
        )
        ..subscribe();
    } catch (_) {
      _stopChannels();
      _activeUserId = userId;
    }
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
    final now = DateTime.now();
    final eventKey = '${event.kind.name}:${event.conversationId}';
    if (_lastEventKey == eventKey &&
        _lastEventAt != null &&
        now.difference(_lastEventAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastEventKey = eventKey;
    _lastEventAt = now;

    void open() => _openConversation(event.conversationId);
    _systemNotification.show(
      contentLabel: event.contentLabel,
      conversationId: event.conversationId,
      onTap: open,
    );

    final context = widget.navigatorKey.currentContext;
    if (context == null) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Hai ricevuto una risposta al tuo ${event.contentLabel}',
          ),
          action: SnackBarAction(label: 'Apri', onPressed: open),
        ),
      );
  }

  void _openConversation(String conversationId) {
    unawaited(RepliesSeenTracker.markNow());
    widget.navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ChestPage(
          focusReplies: true,
          focusConversationId: conversationId,
          highlightLatest: true,
        ),
      ),
    );
  }

  void _stopChannels() {
    _replyEventSubscription?.cancel();
    _replyEventSubscription = null;
    _honooChannel?.unsubscribe();
    _hinooChannel?.unsubscribe();
    _honooChannel = null;
    _hinooChannel = null;
    _activeUserId = null;
  }

  @override
  void dispose() {
    _stopChannels();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
