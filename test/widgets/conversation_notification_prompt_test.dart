import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Services/content_feed_service.dart';
import 'package:honoo/Services/reply_system_notification.dart';
import 'package:honoo/Widgets/conversation_notification_prompt.dart';

class _FakeContentFeedService extends ContentFeedService {
  const _FakeContentFeedService(this.hasRoots);

  final bool hasRoots;

  @override
  Future<bool> hasConversationRoots(String ownerId) async => hasRoots;
}

class _FakeReplyNotification extends ReplySystemNotification {
  _FakeReplyNotification();

  ReplyNotificationPermission current = ReplyNotificationPermission.prompt;
  int requests = 0;

  @override
  ReplyNotificationPermission get permission => current;

  @override
  Future<ReplyNotificationPermission> requestPermission() async {
    requests++;
    current = ReplyNotificationPermission.granted;
    return current;
  }

  @override
  void show({
    required String contentLabel,
    required String conversationId,
    required VoidCallback onTap,
  }) {}
}

void main() {
  test('propone le notifiche solo prima della prima conversazione', () async {
    expect(
      await ConversationNotificationPrompt.shouldOfferForFirstConversation(
        'user-1',
        contentFeedService: const _FakeContentFeedService(false),
      ),
      isTrue,
    );
    expect(
      await ConversationNotificationPrompt.shouldOfferForFirstConversation(
        'user-1',
        contentFeedService: const _FakeContentFeedService(true),
      ),
      isFalse,
    );
  });

  testWidgets('il dialog attiva le notifiche dopo la conferma', (tester) async {
    final notification = _FakeReplyNotification();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ConversationNotificationPrompt.show(
              context,
              notification: notification,
            ),
            child: const Text('Salva'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();

    expect(find.text('Vuoi attivare le notifiche?'), findsOneWidget);
    expect(find.text('Attiva notifiche'), findsOneWidget);

    await tester.tap(find.text('Attiva notifiche'));
    await tester.pumpAndSettle();

    expect(notification.requests, 1);
    expect(find.text('Notifiche attivate.'), findsOneWidget);
  });
}
