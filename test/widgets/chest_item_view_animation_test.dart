import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Entities/chest_item.dart';
import 'package:honoo/Entities/conversation_entry.dart';
import 'package:honoo/Entities/honoo.dart';
import 'package:honoo/UI/honoo_card.dart';
import 'package:honoo/UI/honoo_thread_view.dart';
import 'package:honoo/UI/unified_thread_view.dart';
import 'package:honoo/Utility/responsive_layout.dart';
import 'package:honoo/Widgets/chest_item_view.dart';

import '../test_supabase_helper.dart';

void main() {
  setUpAll(registerSupabaseFallbacks);

  late SupabaseTestHarness harness;

  setUp(() {
    harness = SupabaseTestHarness(withAuthenticatedUser: true)
      ..enableOverrides();
  });

  tearDown(() => harness.disableOverrides());

  testWidgets('un Honoo singolo non usa viste o transizioni di conversazione', (
    tester,
  ) async {
    final honoo = Honoo(
      0,
      'Honoo singolo',
      '',
      '2026-07-25T10:00:00Z',
      '2026-07-25T10:00:00Z',
      'test_user',
      HonooType.personal,
    )..dbId = 'honoo-single';
    final item = ChestItem.honoo(honoo, DateTime.parse('2026-07-25T10:00:00Z'));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChestItemView(
            item: item,
            availableHeight: 700,
            maxWidth: 390,
            honooMetrics: ResponsiveLayout.honooBuilderMetrics(
              availableHeight: 700,
              maxWidth: 390,
              mode: ResponsiveLayoutMode.mobile,
            ),
            repaintKey: GlobalKey(),
            hinooRepliesByRoot: const {},
            isNormalMode: true,
            isActive: true,
            highlightLatest: false,
            focusConversationId: null,
            revealEntryId: null,
            onSelectConversationEntry: (ConversationEntry _) {},
            onDownload: (_) {},
            conversationRefreshToken: 0,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(HonooCard), findsOneWidget);
    expect(find.byType(HonooThreadView), findsNothing);
    expect(find.byType(UnifiedThreadView), findsNothing);
    final chestItem = find.byType(ChestItemView);
    expect(
      find.descendant(of: chestItem, matching: find.byType(AnimatedSwitcher)),
      findsNothing,
    );
    expect(
      find.descendant(of: chestItem, matching: find.byType(SlideTransition)),
      findsNothing,
    );
    expect(
      find.descendant(of: chestItem, matching: find.byType(ScaleTransition)),
      findsNothing,
    );
    expect(
      find.descendant(of: chestItem, matching: find.byType(FadeTransition)),
      findsNothing,
    );
  });
}
