import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Entities/reply_notification_event.dart';

void main() {
  test('riconosce una nuova risposta Honoo destinata all’utente', () {
    final event = ReplyNotificationEvent.fromRealtimePayload(
      {
        'eventType': 'INSERT',
        'new': {
          'destination': 'reply',
          'reply_to': 'root-1',
          'conversation_id': 'conversation-1',
          'recipient_tag': 'me',
          'user_id': 'other',
        },
      },
      kind: ReplyNotificationKind.honoo,
      currentUserId: 'me',
    );

    expect(event, isNotNull);
    expect(event!.conversationId, 'conversation-1');
    expect(event.contentLabel, 'honoo');
  });

  test('riconosce una nuova risposta Hinoo', () {
    final event = ReplyNotificationEvent.fromRealtimePayload(
      {
        'event_type': 'insert',
        'record': {
          'type': 'answer',
          'reply_to': 'root-1',
          'conversation_id': 'conversation-1',
          'recipient_tag': 'me',
          'user_id': 'other',
        },
      },
      kind: ReplyNotificationKind.hinoo,
      currentUserId: 'me',
    );

    expect(event, isNotNull);
    expect(event!.contentLabel, 'hinoo');
  });

  test('ignora record propri, altri destinatari e update', () {
    Map<String, dynamic> payload({
      String event = 'INSERT',
      String recipient = 'me',
      String sender = 'other',
    }) =>
        {
          'eventType': event,
          'new': {
            'destination': 'reply',
            'reply_to': 'root-1',
            'conversation_id': 'conversation-1',
            'recipient_tag': recipient,
            'user_id': sender,
          },
        };

    ReplyNotificationEvent? parse(Map<String, dynamic> value) =>
        ReplyNotificationEvent.fromRealtimePayload(
          value,
          kind: ReplyNotificationKind.honoo,
          currentUserId: 'me',
        );

    expect(parse(payload(sender: 'me')), isNull);
    expect(parse(payload(recipient: 'someone-else')), isNull);
    expect(parse(payload(event: 'UPDATE')), isNull);
  });
}
