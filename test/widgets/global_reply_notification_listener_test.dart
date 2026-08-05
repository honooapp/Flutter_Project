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
  int? replyCount;

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
    int replyCount = 1,
  }) {
    showCount += 1;
    this.contentLabel = contentLabel;
    this.conversationId = conversationId;
    this.onTap = onTap;
    this.replyCount = replyCount;
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
      await tester.pump(const Duration(milliseconds: 200));

      expect(notification.showCount, 1);
      expect(notification.contentLabel, 'hinoo');
      expect(notification.conversationId, 'conversation-42');
      expect(notification.replyCount, 1);
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

  testWidgets(
    'un grande burst produce una sola notifica e un solo aggiornamento UI',
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

      for (var i = 0; i < 1000; i++) {
        events.add(
          ReplyNotificationEvent(
            kind: i.isEven
                ? ReplyNotificationKind.honoo
                : ReplyNotificationKind.hinoo,
            conversationId: 'conversation-$i',
            senderId: 'sender-${i % 200}',
            recipientId: 'test_user',
            replyId: 'reply-$i',
            createdAt: DateTime.utc(
              2026,
              8,
              3,
              10,
            ).add(Duration(milliseconds: i)),
          ),
        );
      }
      await tester.pump(const Duration(milliseconds: 200));

      expect(notification.showCount, 1);
      expect(notification.replyCount, 1000);
      expect(notification.conversationId, 'conversation-999');
      expect(ReplyNotificationSignal.revision.value, initialRevision + 1);
      expect(find.text('Hai ricevuto 1000 nuove risposte'), findsOneWidget);

      notification.onTap!();
      await tester.pumpAndSettle();
      final chestPage = tester.widget<ChestPage>(find.byType(ChestPage));
      expect(chestPage.focusConversationId, 'conversation-999');
      expect(chestPage.focusReplyId, 'reply-999');

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
