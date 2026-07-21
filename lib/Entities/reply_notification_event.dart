enum ReplyNotificationKind { honoo, hinoo }

class ReplyNotificationEvent {
  const ReplyNotificationEvent({
    required this.kind,
    required this.conversationId,
    required this.senderId,
    required this.recipientId,
  });

  final ReplyNotificationKind kind;
  final String conversationId;
  final String senderId;
  final String recipientId;

  String get contentLabel =>
      kind == ReplyNotificationKind.honoo ? 'honoo' : 'hinoo';

  static ReplyNotificationEvent? fromRealtimePayload(
    dynamic payload, {
    required ReplyNotificationKind kind,
    required String currentUserId,
  }) {
    if (payload is! Map) return null;
    final eventType =
        (payload['eventType'] ?? payload['event_type'])?.toString();
    if (eventType != null && eventType.toLowerCase() != 'insert') return null;

    final dynamic rawRecord = payload['new'] ?? payload['record'];
    if (rawRecord is! Map) return null;
    final record = Map<String, dynamic>.from(rawRecord);
    final recipientId = record['recipient_tag']?.toString() ?? '';
    final senderId = record['user_id']?.toString() ?? '';
    final conversationId = record['conversation_id']?.toString() ?? '';
    if (recipientId != currentUserId ||
        senderId.isEmpty ||
        senderId == currentUserId ||
        conversationId.isEmpty) {
      return null;
    }

    final replyTo = record['reply_to']?.toString() ?? '';
    final bool isReply = switch (kind) {
      ReplyNotificationKind.honoo =>
        record['destination']?.toString() == 'reply' && replyTo.isNotEmpty,
      ReplyNotificationKind.hinoo =>
        (record['type']?.toString() == 'answer' || replyTo.isNotEmpty),
    };
    if (!isReply) return null;

    return ReplyNotificationEvent(
      kind: kind,
      conversationId: conversationId,
      senderId: senderId,
      recipientId: recipientId,
    );
  }
}
