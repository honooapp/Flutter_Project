import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Entities/chest_item.dart';
import 'package:honoo/Entities/conversation_entry.dart';
import 'package:honoo/Entities/hinoo.dart';
import 'package:honoo/Entities/honoo.dart';
import 'package:honoo/Widgets/chest_footer.dart';

void main() {
  ChestItem honooItem(HonooType type, {bool isOnMoon = false}) {
    final honoo = Honoo(
      1,
      'Test',
      '',
      '2026-01-01T00:00:00Z',
      '2026-01-01T00:00:00Z',
      type == HonooType.answer ? 'another-user' : 'current-user',
      type,
    )..isOnMoon = isOnMoon;
    return ChestItem.honoo(honoo, DateTime.utc(2026));
  }

  ChestItem hinooItem({bool isOnMoon = false}) => ChestItem.hinoo(
        ChestHinooItem(
          id: 'hinoo-1',
          draft: const HinooDraft(
            pages: [
              HinooSlide(
                backgroundImage: null,
                text: 'Test',
                isTextWhite: true,
              ),
            ],
          ),
          createdAt: DateTime.utc(2026),
          isFromMoonSaved: false,
          ownerId: 'current-user',
          isOnMoon: isOnMoon,
        ),
      );

  Future<void> pumpFooter(
    WidgetTester tester, {
    required ChestItem? item,
    ValueChanged<Honoo>? onSendHonooToMoon,
    ValueChanged<Honoo>? onDeleteHonoo,
    ValueChanged<ChestHinooItem>? onSendHinooToMoon,
    ValueChanged<ChestHinooItem>? onDeleteHinoo,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChestFooter(
            item: item,
            selectedConversationEntry: null,
            currentUserId: 'current-user',
            iconSize: 40,
            gap: 24,
            bottomPadding: 10,
            onHome: () {},
            onInfo: () {},
            onSendHonooToMoon: onSendHonooToMoon ?? (_) {},
            onReplyToHonoo: (_) {},
            onDeleteHonoo: onDeleteHonoo ?? (_) {},
            onSendHinooToMoon: onSendHinooToMoon ?? (_) {},
            onReplyToHinoo: (_) {},
            onDeleteHinoo: onDeleteHinoo ?? (_) {},
            onSendConversationEntryToMoon: (ConversationEntry _) {},
          ),
        ),
      ),
    );
  }

  testWidgets('footer vuoto mostra Home e Info con Home senza filtro colore',
      (tester) async {
    await pumpFooter(tester, item: null);

    expect(find.byTooltip('Home'), findsOneWidget);
    expect(find.byTooltip('Info'), findsOneWidget);
    expect(find.byType(IconButton), findsNWidgets(2));
    final icons =
        tester.widgetList<SvgPicture>(find.byType(SvgPicture)).toList();
    expect(icons.first.colorFilter, isNull);
    expect(icons.last.colorFilter, isNotNull);
  });

  testWidgets('Honoo personale mostra Luna e Cancella e inoltra le azioni',
      (tester) async {
    var sent = false;
    var deleted = false;
    await pumpFooter(
      tester,
      item: honooItem(HonooType.personal),
      onSendHonooToMoon: (_) => sent = true,
      onDeleteHonoo: (_) => deleted = true,
    );

    expect(find.byType(IconButton), findsNWidgets(4));
    expect(find.byTooltip('Spedisci sulla Luna'), findsOneWidget);
    expect(find.byTooltip('Cancella'), findsOneWidget);
    await tester.tap(find.byTooltip('Spedisci sulla Luna'));
    await tester.tap(find.byTooltip('Cancella'));
    expect(sent, isTrue);
    expect(deleted, isTrue);
  });

  testWidgets('Hinoo personale mostra Luna e Cancella e inoltra le azioni',
      (tester) async {
    var sent = false;
    var deleted = false;
    await pumpFooter(
      tester,
      item: hinooItem(),
      onSendHinooToMoon: (_) => sent = true,
      onDeleteHinoo: (_) => deleted = true,
    );

    expect(find.byType(IconButton), findsNWidgets(4));
    await tester.tap(find.byTooltip('Spedisci sulla Luna'));
    await tester.tap(find.byTooltip('Cancella'));
    expect(sent, isTrue);
    expect(deleted, isTrue);
  });

  testWidgets('Honoo già sulla Luna non mostra una seconda azione Luna',
      (tester) async {
    await pumpFooter(
      tester,
      item: honooItem(HonooType.personal, isOnMoon: true),
    );

    expect(find.byTooltip('Spedisci sulla Luna'), findsNothing);
    expect(find.byTooltip('Cancella'), findsOneWidget);
  });

  testWidgets('Hinoo già sulla Luna non mostra una seconda azione Luna',
      (tester) async {
    await pumpFooter(tester, item: hinooItem(isOnMoon: true));

    expect(find.byTooltip('Spedisci sulla Luna'), findsNothing);
    expect(find.byTooltip('Cancella'), findsOneWidget);
  });

  testWidgets('contenuto ricevuto mostra solo Home, Info e Cancella',
      (tester) async {
    await pumpFooter(tester, item: honooItem(HonooType.answer));

    expect(find.byType(IconButton), findsNWidgets(3));
    expect(find.byTooltip('Home'), findsOneWidget);
    expect(find.byTooltip('Info'), findsOneWidget);
    expect(find.byTooltip('Cancella'), findsOneWidget);
    expect(find.byTooltip('Spedisci sulla Luna'), findsNothing);
    expect(find.byTooltip('Rispondi'), findsNothing);
  });
}
