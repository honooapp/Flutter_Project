import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Entities/hinoo.dart';
import 'package:honoo/Entities/honoo.dart';
import 'package:honoo/UI/hinoo_viewer.dart';
import 'package:honoo/UI/honoo_card.dart';
import 'package:honoo/Utility/honoo_colors.dart';

import '../test_supabase_helper.dart';

void main() {
  setUpAll(registerSupabaseFallbacks);

  late SupabaseTestHarness harness;

  setUp(() {
    harness = SupabaseTestHarness(withAuthenticatedUser: true)
      ..enableOverrides();
  });

  tearDown(() {
    harness.disableOverrides();
  });

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
        border.right.color == color &&
        border.bottom.color == color &&
        border.left.color == color &&
        border.top.width == 6;
  });

  Honoo honoo({
    required HonooType type,
    String owner = 'other_user',
    bool fromMoon = false,
  }) {
    return Honoo(
      0,
      'Test conversazione',
      '',
      '2026-07-18T10:00:00Z',
      '2026-07-18T10:00:00Z',
      owner,
      type,
    )..isFromMoonSaved = fromMoon;
  }

  HinooDraft hinoo({bool fromMoon = false}) => HinooDraft(
    pages: const [
      HinooSlide(
        backgroundImage: null,
        text: 'Test conversazione',
        isTextWhite: true,
      ),
    ],
    type: HinooType.personal,
    isFromMoonSaved: fromMoon,
  );

  Future<void> pumpHonoo(WidgetTester tester, Honoo value) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 500,
            height: 750,
            child: HonooCard(honoo: value),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> pumpHinoo(
    WidgetTester tester, {
    required HinooDraft draft,
    required bool isReply,
    required String authorId,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HinooViewer(
            draft: draft,
            maxWidth: 500,
            maxHeight: 750,
            isReply: isReply,
            authorId: authorId,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('Honoo di risposta proprio non ha cornice', (tester) async {
    await pumpHonoo(
      tester,
      honoo(type: HonooType.answer, owner: 'test_user', fromMoon: true),
    );

    expect(borderWithColor(HonooColor.secondary), findsNothing);
    expect(borderWithColor(Colors.white), findsNothing);
  });

  testWidgets('Honoo ricevuto in risposta ha cornice rossa', (tester) async {
    await pumpHonoo(tester, honoo(type: HonooType.answer));

    expect(borderWithColor(HonooColor.secondary), findsWidgets);
    expect(borderWithColor(Colors.white), findsNothing);
  });

  testWidgets('Honoo salvato dalla Luna non ha cornice', (tester) async {
    await pumpHonoo(
      tester,
      honoo(type: HonooType.personal, owner: 'test_user', fromMoon: true),
    );

    expect(borderWithColor(Colors.white), findsNothing);
    expect(borderWithColor(HonooColor.secondary), findsNothing);
  });

  testWidgets('Hinoo di risposta proprio non ha cornice', (tester) async {
    await pumpHinoo(
      tester,
      draft: hinoo(fromMoon: true),
      isReply: true,
      authorId: 'test_user',
    );

    expect(borderWithColor(HonooColor.secondary), findsNothing);
    expect(borderWithColor(Colors.white), findsNothing);
  });

  testWidgets('Hinoo ricevuto in risposta ha cornice rossa', (tester) async {
    await pumpHinoo(
      tester,
      draft: hinoo(),
      isReply: true,
      authorId: 'other_user',
    );

    expect(borderWithColor(HonooColor.secondary), findsWidgets);
    expect(borderWithColor(Colors.white), findsNothing);
  });

  testWidgets('Hinoo salvato dalla Luna ha solo cornice bianca', (
    tester,
  ) async {
    await pumpHinoo(
      tester,
      draft: hinoo(fromMoon: true),
      isReply: false,
      authorId: 'test_user',
    );

    expect(borderWithColor(Colors.white), findsWidgets);
    expect(borderWithColor(HonooColor.secondary), findsNothing);
  });
}
