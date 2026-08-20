import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/IsolaDelleStorie/Pages/campanelli_page.dart';
import 'package:honoo/Widgets/campanelli_footer.dart';
import 'package:honoo/Widgets/campanello_card.dart';
import 'package:honoo/Widgets/casa_section.dart';
import 'package:honoo/Widgets/desktop_carousel_arrows.dart';
import 'package:mocktail/mocktail.dart';

import '../test_supabase_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseTestHarness harness;

  setUpAll(registerSupabaseFallbacks);

  setUp(() {
    harness = SupabaseTestHarness();
    harness.enableOverrides();
  });

  tearDown(() => harness.disableOverrides());

  Future<void> pumpAtSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: CampanelliPage()));
    await tester.pump();
  }

  testWidgets('Campanelli mantiene la struttura su viewport mobile', (
    tester,
  ) async {
    await pumpAtSize(tester, const Size(390, 844));

    expect(find.byType(CampanelloCard), findsOneWidget);
    expect(find.byType(CampanelliFooter), findsOneWidget);
    expect(find.byType(DesktopCarouselArrows), findsOneWidget);
    final CampanelloCard card = tester.widget(find.byType(CampanelloCard));
    expect(card.width, 390);
    expect(card.height, 844);
    final DesktopCarouselArrows arrows = tester.widget(
      find.byType(DesktopCarouselArrows),
    );
    expect(arrows.arrowSize, 24);
    expect(arrows.arrowAlignment, Alignment.center);
    expect(arrows.verticalInset, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('le frecce del carosello si dissolvono dopo quattro secondi', (
    tester,
  ) async {
    await pumpAtSize(tester, const Size(390, 844));

    AnimatedOpacity arrows = tester.widget(
      find.byKey(const ValueKey<String>('campanelli_carousel_arrows')),
    );
    expect(arrows.opacity, 1);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 300));

    arrows = tester.widget(
      find.byKey(const ValueKey<String>('campanelli_carousel_arrows')),
    );
    expect(arrows.opacity, 0);
  });

  testWidgets('Campanelli mantiene la struttura su viewport desktop', (
    tester,
  ) async {
    harness.disableOverrides();
    harness = SupabaseTestHarness(withAuthenticatedUser: true);
    harness.enableOverrides();
    final houses = harness.stubTable('case');
    final settings = harness.stubTable('house_share_settings');
    final hinoo = harness.stubTable('hinoo');
    final houseAccess = harness.stubTable('house_access');
    final houseInvites = harness.stubTable('house_invites');
    when(() => harness.user.email).thenReturn('utente@example.com');
    when(
      () => houseAccess.not('granted_at', 'is', null),
    ).thenAnswer((_) => houseAccess);
    houses.queueResponse(const [
      {
        'campanello_hinoo_id': 'owned',
        'owner_id': 'test_user',
        'created_at': '2026-08-20T10:00:00Z',
      },
      {
        'campanello_hinoo_id': 'other',
        'owner_id': 'other_user',
        'created_at': '2026-08-19T10:00:00Z',
      },
    ]);
    settings.queueResponse(const []);
    hinoo.queueResponse(const [
      {
        'id': 'owned',
        'pages': [
          {'text': 'Il mio campanello'},
        ],
      },
      {
        'id': 'other',
        'pages': [
          {'text': 'Un altro campanello'},
        ],
      },
    ]);
    houseAccess
      ..queueResponse(const [])
      ..queueResponse(const []);
    houseInvites.queueResponse(const []);

    await pumpAtSize(tester, const Size(1200, 900));
    await tester.pumpAndSettle();

    expect(find.byType(CampanelloCard), findsOneWidget);
    expect(find.byType(CampanelliFooter), findsOneWidget);
    final CampanelloCard card = tester.widget(find.byType(CampanelloCard));
    expect(card.width, closeTo(506.25, 0.01));
    expect(card.height, 900);
    expect(tester.getSize(find.byType(CampanelliFooter)).width, 506.25);
    final DesktopCarouselArrows arrows = tester.widget(
      find.byType(DesktopCarouselArrows),
    );
    expect(arrows.arrowSize, 28);
    expect(arrows.arrowAlignment, Alignment.center);

    await tester.drag(find.byType(CampanelloCard), const Offset(0, -900));
    await tester.pumpAndSettle();

    final CasaSection casa = tester.widget(find.byType(CasaSection));
    expect(find.byType(DesktopCarouselArrows), findsNothing);
    expect(casa.width, closeTo(506.25, 0.01));
    expect(casa.height, 900);
    expect(tester.takeException(), isNull);
  });
}
