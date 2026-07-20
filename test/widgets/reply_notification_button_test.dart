import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Services/reply_system_notification.dart';
import 'package:honoo/Widgets/reply_notification_button.dart';

class _FakeReplyNotification extends ReplySystemNotification {
  ReplyNotificationPermission current = ReplyNotificationPermission.prompt;
  int requests = 0;

  @override
  ReplyNotificationPermission get permission => current;

  @override
  Future<ReplyNotificationPermission> requestPermission() async {
    requests += 1;
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
  testWidgets('il pulsante configura le notifiche del browser', (tester) async {
    final notification = _FakeReplyNotification();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReplyNotificationButton(notification: notification),
        ),
      ),
    );

    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    await tester.tap(find.byKey(const Key('configure_reply_notifications')));
    await tester.pump();

    expect(notification.requests, 1);
    expect(find.byIcon(Icons.notifications_active), findsOneWidget);
    expect(find.text('Notifiche attivate.'), findsOneWidget);
  });
}
