import 'reply_system_notification.dart';

ReplySystemNotification createNotification() =>
    const _UnsupportedReplySystemNotification();

class _UnsupportedReplySystemNotification extends ReplySystemNotification {
  const _UnsupportedReplySystemNotification();

  @override
  ReplyNotificationPermission get permission =>
      ReplyNotificationPermission.unsupported;

  @override
  Future<ReplyNotificationPermission> requestPermission() async => permission;

  @override
  void show({
    required String contentLabel,
    required String conversationId,
    required void Function() onTap,
    int replyCount = 1,
  }) {}
}
