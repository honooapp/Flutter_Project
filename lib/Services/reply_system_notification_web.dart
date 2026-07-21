import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'reply_system_notification.dart';

ReplySystemNotification createNotification() =>
    const _WebReplySystemNotification();

class _WebReplySystemNotification extends ReplySystemNotification {
  const _WebReplySystemNotification();

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
  void show({
    required String contentLabel,
    required String conversationId,
    required void Function() onTap,
  }) {
    if (permission != ReplyNotificationPermission.granted) return;
    final notification = web.Notification(
      'Nuova risposta su honoo',
      web.NotificationOptions(
        body: 'Hai ricevuto una risposta al tuo $contentLabel.',
        icon: 'icons/Icon-192.png',
        tag: 'honoo-reply-$conversationId',
      ),
    );
    notification.onclick = ((web.Event _) {
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
