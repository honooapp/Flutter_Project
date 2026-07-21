// ignore_for_file: avoid_web_libraries_in_flutter

// ignore: deprecated_member_use
import 'dart:html' as html;

import 'reply_system_notification.dart';

ReplySystemNotification createNotification() =>
    const _WebReplySystemNotification();

class _WebReplySystemNotification extends ReplySystemNotification {
  const _WebReplySystemNotification();

  @override
  ReplyNotificationPermission get permission {
    if (!html.Notification.supported) {
      return ReplyNotificationPermission.unsupported;
    }
    return _mapPermission(html.Notification.permission);
  }

  @override
  Future<ReplyNotificationPermission> requestPermission() async {
    if (!html.Notification.supported) return permission;
    final result = await html.Notification.requestPermission();
    return _mapPermission(result);
  }

  @override
  void show({
    required String contentLabel,
    required String conversationId,
    required void Function() onTap,
  }) {
    if (permission != ReplyNotificationPermission.granted) return;
    final notification = html.Notification(
      'Nuova risposta su honoo',
      body: 'Hai ricevuto una risposta al tuo $contentLabel.',
      icon: 'icons/Icon-192.png',
      tag: 'honoo-reply-$conversationId',
    );
    notification.onClick.first.then((_) {
      notification.close();
      onTap();
    });
  }
}

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
