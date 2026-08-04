import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Entities/conversation_entry.dart';
import 'package:honoo/Entities/honoo.dart';
import 'package:honoo/UI/unified_thread_view.dart';
import 'package:honoo/Utility/honoo_colors.dart';

import '../test_supabase_helper.dart';

void main() {
  late SupabaseTestHarness harness;

  setUpAll(registerSupabaseFallbacks);

  setUp(() {
    harness = SupabaseTestHarness(withAuthenticatedUser: true)
      ..enableOverrides();
  });

  tearDown(() => harness.disableOverrides());

  Honoo honoo({
    required String id,
    required String text,
    required String owner,
    required String createdAt,
    HonooType type = HonooType.personal,
    String? replyTo,
    bool fromMoon = false,
  }) {
    final value = Honoo(0, text, '', createdAt, createdAt, owner, type)
      ..dbId = id
      ..replyTo = replyTo
      ..isFromMoonSaved = fromMoon
      ..conversationId = 'conversation-1';
    return value;
  }

  Finder borderWithColor(Color color) => find.byWidgetPredicate((widget) {
    final Decoration? decoration = switch (widget) {
      Container(:final decoration) => decoration,
      DecoratedBox(:final decoration) => decoration,
      _ => null,
    };
    if (decoration is! BoxDecoration) return false;
    final border = decoration.border;
    return border is Border &&
        border.top.color == color &&
        border.top.width == 6;
  });

  testWidgets('il bounce rivela il messaggio padre fino a metà schermo', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(600, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final root = ConversationEntry.honoo(
      honoo(
        id: 'root-1',
        text: 'Messaggio padre',
        owner: 'me',
        createdAt: '2026-07-20T10:00:00Z',
      ),
    );
    final reply = ConversationEntry.honoo(
      honoo(
        id: 'reply-1',
        text: 'Ultima risposta ricevuta',
        owner: 'other',
        createdAt: '2026-07-20T11:00:00Z',
        type: HonooType.answer,
        replyTo: 'root-1',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UnifiedThreadView(
            conversationId: 'conversation-1',
            maxWidth: 600,
            maxHeight: 700,
            isActive: true,
            currentUserId: 'me',
            conversationLoader: (_) async => [root, reply],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Ultima risposta ricevuta'), findsOneWidget);
    expect(find.text('Messaggio padre'), findsOneWidget);
    expect(find.byKey(const Key('reply_reveal_parent')), findsOneWidget);
    final foreground = tester.widget<Transform>(
      find.byKey(const Key('reply_reveal_foreground')),
    );
    expect(foreground.transform.getTranslation().y, lessThan(0));
    expect(foreground.transform.getTranslation().y, greaterThanOrEqualTo(-336));
  });

  testWidgets('una conversazione senza messaggi non crea una pagina vuota', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UnifiedThreadView(
            conversationId: 'empty-conversation',
            maxWidth: 390,
            maxHeight: 700,
            conversationLoader: (_) async => const [],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Conversazione vuota'), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
  });

  testWidgets('una nuova risposta riavvia il reveal dopo il refresh', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(600, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final root = ConversationEntry.honoo(
      honoo(
        id: 'root-refresh',
        text: 'Padre aggiornato',
        owner: 'me',
        createdAt: '2026-07-20T10:00:00Z',
      ),
    );
    final firstReply = ConversationEntry.honoo(
      honoo(
        id: 'reply-refresh-1',
        text: 'Prima risposta',
        owner: 'other',
        createdAt: '2026-07-20T11:00:00Z',
        type: HonooType.answer,
        replyTo: 'root-refresh',
      ),
    );
    final secondReply = ConversationEntry.honoo(
      honoo(
        id: 'reply-refresh-2',
        text: 'Seconda risposta appena salvata',
        owner: 'me',
        createdAt: '2026-07-20T12:00:00Z',
        type: HonooType.answer,
        replyTo: 'reply-refresh-1',
      ),
    );
    var entries = [root, firstReply];

    Widget app(int refreshToken) => MaterialApp(
      home: Scaffold(
        body: UnifiedThreadView(
          key: const Key('refreshable-thread'),
          conversationId: 'conversation-1',
          maxWidth: 600,
          maxHeight: 700,
          isActive: true,
          currentUserId: 'me',
          refreshToken: refreshToken,
          conversationLoader: (_) async => entries,
        ),
      ),
    );

    await tester.pumpWidget(app(0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    entries = [root, firstReply, secondReply];
    await tester.pumpWidget(app(1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Seconda risposta appena salvata'), findsOneWidget);
    final foreground = tester.widget<Transform>(
      find.byKey(const Key('reply_reveal_foreground')),
    );
    expect(foreground.transform.getTranslation().y, lessThan(0));
    expect(find.byKey(const Key('reply_reveal_parent')), findsOneWidget);
  });

  testWidgets('lo swipe resta sulla pagina scelta dopo il rebuild del padre', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(600, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final root = ConversationEntry.honoo(
      honoo(
        id: 'root-scroll',
        text: 'Contenuto a cui si è risposto',
        owner: 'me',
        createdAt: '2026-07-20T10:00:00Z',
      ),
    );
    final reply = ConversationEntry.honoo(
      honoo(
        id: 'reply-scroll',
        text: 'Risposta inizialmente visibile',
        owner: 'other',
        createdAt: '2026-07-20T11:00:00Z',
        type: HonooType.answer,
        replyTo: 'root-scroll',
      ),
    );
    String? selectedId;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: UnifiedThreadView(
              conversationId: 'conversation-1',
              maxWidth: 600,
              maxHeight: 700,
              isActive: true,
              currentUserId: 'me',
              conversationLoader: (_) async => [root, reply],
              onSelect: (entry) {
                selectedId = entry.id;
                setState(() {});
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    expect(selectedId, 'reply-scroll');

    await tester.drag(find.byType(PageView), const Offset(0, -650));
    await tester.pumpAndSettle();

    expect(selectedId, 'root-scroll');
    expect(find.text('Contenuto a cui si è risposto'), findsOneWidget);
  });

  testWidgets('un errore di conversazione mostra Riprova', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UnifiedThreadView(
            conversationId: 'failed-conversation',
            maxWidth: 390,
            maxHeight: 700,
            conversationLoader: (_) async => throw Exception('offline'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Non riesco a caricare la conversazione.'),
      findsOneWidget,
    );
    expect(find.text('Riprova'), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
  });

  testWidgets('le conversazioni usano pagine senza overscroll elastico', (
    tester,
  ) async {
    final entry = ConversationEntry.honoo(
      honoo(
        id: 'root-physics',
        text: 'Messaggio',
        owner: 'me',
        createdAt: '2026-07-20T10:00:00Z',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UnifiedThreadView(
            conversationId: 'conversation-physics',
            maxWidth: 390,
            maxHeight: 700,
            conversationLoader: (_) async => [entry],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.physics, isA<PageScrollPhysics>());
    expect(pageView.physics?.parent, isA<ClampingScrollPhysics>());
  });

  testWidgets(
    'il bounce mostra la risposta propria senza bordo e il padre Luna bianco',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(600, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final root = ConversationEntry.honoo(
        honoo(
          id: 'saved-root-1',
          text: 'Messaggio salvato dalla Luna',
          owner: 'test_user',
          createdAt: '2026-07-20T10:00:00Z',
          fromMoon: true,
        ),
      );
      final reply = ConversationEntry.honoo(
        honoo(
          id: 'reply-1',
          text: 'La mia risposta',
          owner: 'test_user',
          createdAt: '2026-07-20T11:00:00Z',
          type: HonooType.answer,
          replyTo: 'moon-root-1',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedThreadView(
              conversationId: 'conversation-1',
              maxWidth: 600,
              maxHeight: 700,
              isActive: true,
              currentUserId: 'test_user',
              conversationLoader: (_) async => [root, reply],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byKey(const Key('reply_reveal_parent')), findsOneWidget);
      expect(borderWithColor(Colors.white), findsWidgets);
      expect(borderWithColor(HonooColor.secondary), findsNothing);
    },
  );

  testWidgets(
    'revealEntryId anima la risposta richiesta, non quella più recente',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(600, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final root = ConversationEntry.honoo(
        honoo(
          id: 'root-exact',
          text: 'Padre esatto',
          owner: 'me',
          createdAt: '2026-07-20T10:00:00Z',
        ),
      );
      final requestedReply = ConversationEntry.honoo(
        honoo(
          id: 'reply-requested',
          text: 'Risposta richiesta',
          owner: 'other',
          createdAt: '2026-07-20T11:00:00Z',
          type: HonooType.answer,
          replyTo: 'root-exact',
        ),
      );
      final newerReply = ConversationEntry.honoo(
        honoo(
          id: 'reply-newer',
          text: 'Risposta più recente',
          owner: 'other',
          createdAt: '2026-07-20T12:00:00Z',
          type: HonooType.answer,
          replyTo: 'reply-requested',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedThreadView(
              conversationId: 'conversation-1',
              revealEntryId: 'reply-requested',
              maxWidth: 600,
              maxHeight: 700,
              isActive: true,
              conversationLoader: (_) async => [
                root,
                requestedReply,
                newerReply,
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Risposta richiesta'), findsOneWidget);
      expect(find.text('Padre esatto'), findsOneWidget);
      expect(find.byKey(const Key('reply_reveal_parent')), findsOneWidget);
    },
  );

  testWidgets('un caricamento vecchio non sostituisce la nuova conversazione', (
    tester,
  ) async {
    final first = Completer<List<ConversationEntry>>();
    final second = Completer<List<ConversationEntry>>();
    Future<List<ConversationEntry>> loader(String conversationId) =>
        conversationId == 'conversation-old' ? first.future : second.future;

    Widget app(String conversationId) => MaterialApp(
      home: Scaffold(
        body: UnifiedThreadView(
          key: const Key('race-thread'),
          conversationId: conversationId,
          maxWidth: 390,
          maxHeight: 700,
          conversationLoader: loader,
        ),
      ),
    );

    await tester.pumpWidget(app('conversation-old'));
    await tester.pump();
    await tester.pumpWidget(app('conversation-new'));
    await tester.pump();

    second.complete([
      ConversationEntry.honoo(
        honoo(
          id: 'new-entry',
          text: 'Conversazione nuova',
          owner: 'me',
          createdAt: '2026-07-20T12:00:00Z',
        ),
      ),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Conversazione nuova'), findsOneWidget);

    first.complete([
      ConversationEntry.honoo(
        honoo(
          id: 'old-entry',
          text: 'Conversazione vecchia',
          owner: 'me',
          createdAt: '2026-07-20T10:00:00Z',
        ),
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Conversazione nuova'), findsOneWidget);
    expect(find.text('Conversazione vecchia'), findsNothing);
  });
}
