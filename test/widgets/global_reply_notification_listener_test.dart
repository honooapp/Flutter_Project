import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Entities/reply_notification_event.dart';
import 'package:honoo/Pages/chest_page.dart';
import 'package:honoo/Services/reply_system_notification.dart';
import 'package:honoo/Widgets/global_reply_notification_listener.dart';
import 'package:honoo/Utility/reply_notification_signal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_supabase_helper.dart';

class _FakeReplySystemNotification extends ReplySystemNotification {
  VoidCallback? onTap;
  String? contentLabel;
  String? conversationId;
  int showCount = 0;

  @override
  ReplyNotificationPermission get permission =>
      ReplyNotificationPermission.granted;

  @override
  Future<ReplyNotificationPermission> requestPermission() async => permission;

  @override
  void show({
    required String contentLabel,
    required String conversationId,
    required VoidCallback onTap,
  }) {
    showCount += 1;
    this.contentLabel = contentLabel;
    this.conversationId = conversationId;
    this.onTap = onTap;
  }
}

void main() {
  setUpAll(registerSupabaseFallbacks);

  late SupabaseTestHarness harness;
  late StreamController<ReplyNotificationEvent> events;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    harness = SupabaseTestHarness(withAuthenticatedUser: true)
      ..enableOverrides();
    harness.stubTable('honoo');
    harness.stubTable('hinoo');
    events = StreamController<ReplyNotificationEvent>();
  });

  tearDown(() async {
    await events.close();
    harness.disableOverrides();
  });

  testWidgets(
    'la notifica apre lo Scrigno sulla conversazione della risposta',
    (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      final notification = _FakeReplySystemNotification();
      final initialRevision = ReplyNotificationSignal.revision.value;

      await tester.pumpWidget(
        GlobalReplyNotificationListener(
          navigatorKey: navigatorKey,
          systemNotification: notification,
          replyEventStream: events.stream,
          child: MaterialApp(
            navigatorKey: navigatorKey,
            home: const Scaffold(body: Text('Luna')),
          ),
        ),
      );

      final event = ReplyNotificationEvent(
        kind: ReplyNotificationKind.hinoo,
        conversationId: 'conversation-42',
        senderId: 'other_user',
        recipientId: 'test_user',
        replyId: 'reply-42',
        createdAt: DateTime.utc(2026, 8, 3, 10),
      );
      events.add(event);
      events.add(event);
      await tester.pump();

      expect(notification.showCount, 1);
      expect(notification.contentLabel, 'hinoo');
      expect(notification.conversationId, 'conversation-42');
      expect(notification.onTap, isNotNull);
      expect(
        ReplyNotificationSignal.revision.value,
        greaterThan(initialRevision),
      );
      expect(
        find.text('Hai ricevuto una risposta al tuo hinoo'),
        findsOneWidget,
      );

      notification.onTap!();
      await tester.pumpAndSettle();

      expect(navigatorKey.currentState!.canPop(), isTrue);
      expect(find.byType(ChestPage), findsOneWidget);
      final chestPage = tester.widget<ChestPage>(find.byType(ChestPage));
      expect(chestPage.focusConversationId, 'conversation-42');
      expect(chestPage.focusReplyId, 'reply-42');

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
