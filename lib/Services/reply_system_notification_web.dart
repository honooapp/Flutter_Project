import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'reply_system_notification.dart';

ReplySystemNotification createNotification() =>
    const _WebReplySystemNotification();

class _WebReplySystemNotification extends ReplySystemNotification {
  const _WebReplySystemNotification();

  static final Map<String, web.Notification> _activeNotifications = {};

  @override
  ReplyNotificationPermission get permission {
    if (!_isSupported) {
      return ReplyNotificationPermission.unsupported;
    }
    return _mapPermission(web.Notification.permission);
  }

  @override
  Future<ReplyNotificationPermission> requestPermission() async {
    if (!_isSupported) return permission;
    final result = await web.Notification.requestPermission().toDart;
    return _mapPermission(result.toDart);
  }

  @override
  void closeConversation(String conversationId) {
    _activeNotifications.remove(conversationId)?.close();
  }

  @override
  void show({
    required String contentLabel,
    required String conversationId,
    required void Function() onTap,
    int replyCount = 1,
  }) {
    if (permission != ReplyNotificationPermission.granted) return;
    closeConversation(conversationId);
    final body = replyCount > 1
        ? 'Hai ricevuto $replyCount nuove risposte'
        : 'Hai ricevuto una risposta al tuo $contentLabel';
    final notification = web.Notification(
      'Nuova risposta su honoo',
      web.NotificationOptions(
        body: body,
        icon: 'icons/Icon-192.png',
        tag: 'honoo-reply-$conversationId',
      ),
    );
    _activeNotifications[conversationId] = notification;
    notification.onclick = ((web.Event _) {
      if (identical(_activeNotifications[conversationId], notification)) {
        _activeNotifications.remove(conversationId);
      }
      notification.close();
      onTap();
    }).toJS;
  }
}

bool get _isSupported => web.window.hasProperty('Notification'.toJS).toDart;

ReplyNotificationPermission _mapPermission(String? value) {
  switch (value) {
    case 'granted':
      return ReplyNotificationPermission.granted;
    case 'denied':
      return ReplyNotificationPermission.denied;
    default:
      return ReplyNotificationPermission.prompt;
  }
}
