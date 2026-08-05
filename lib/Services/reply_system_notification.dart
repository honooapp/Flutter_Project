import 'reply_system_notification_stub.dart'
    if (dart.library.html) 'reply_system_notification_web.dart'
    as platform;

enum ReplyNotificationPermission { unsupported, prompt, granted, denied }

abstract class ReplySystemNotification {
  const ReplySystemNotification();

  factory ReplySystemNotification.platform() => platform.createNotification();

  ReplyNotificationPermission get permission;

  Future<ReplyNotificationPermission> requestPermission();

  void closeConversation(String conversationId) {}

  void show({
    required String contentLabel,
    required String conversationId,
    required void Function() onTap,
    int replyCount = 1,
  });
}
