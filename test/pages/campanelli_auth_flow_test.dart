import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/IsolaDelleStorie/Pages/campanelli_page.dart';
import 'package:honoo/Pages/email_login_page.dart';
import 'package:honoo/Widgets/campanello_card.dart';
import 'package:mocktail/mocktail.dart';

import '../test_supabase_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(registerSupabaseFallbacks);

  late SupabaseTestHarness harness;

  setUp(() {
    harness = SupabaseTestHarness();
    harness.enableOverrides();
  });

  tearDown(() => harness.disableOverrides());

  testWidgets(
    'un ospite vede presentazione, i due admin in ordine e poi il login',
    (tester) async {
      final rpc = MockQueryChain();
      rpc.queueResponse(const [
        {
          'admin_email': 'venceslao.cembalo@gmail.com',
          'campanello_hinoo_id': 'hinoo-venceslao',
          'owner_id': 'admin-venceslao',
          'house_image_url': null,
          'pages': [
            {
              'backgroundImage': null,
              'text': 'Campanello di Venceslao',
              'isTextWhite': true,
            },
          ],
        },
        {
          'admin_email': 'mariandreealavric@gmail.com',
          'campanello_hinoo_id': 'hinoo-mariandreea',
          'owner_id': 'admin-mariandreea',
          'house_image_url': null,
          'pages': [
            {
              'backgroundImage': null,
              'text': 'Campanello di Mari Andreea',
              'isTextWhite': false,
            },
          ],
        },
      ]);
      when(
        () => harness.client.rpc('get_public_admin_campanelli'),
      ).thenAnswer((_) => rpc);

      await tester.pumpWidget(const MaterialApp(home: CampanelliPage()));
      await tester.pumpAndSettle();

      CampanelloCard card = tester.widget(find.byType(CampanelloCard));
      expect(card.data.isIntro, isTrue);

      await tester.drag(find.byType(CampanelloCard), const Offset(-500, 0));
      await tester.pumpAndSettle();
      card = tester.widget(find.byType(CampanelloCard));
      expect(card.data.campanello?.campanelloHinooId, 'hinoo-venceslao');
      expect(card.data.text, 'Campanello di Venceslao');
      expect(card.data.text, isNot(contains('Magari sono a casa')));

      await tester.drag(find.byType(CampanelloCard), const Offset(-500, 0));
      await tester.pumpAndSettle();
      card = tester.widget(find.byType(CampanelloCard));
      expect(card.data.campanello?.campanelloHinooId, 'hinoo-mariandreea');
      expect(card.data.text, 'Campanello di Mari Andreea');
      expect(card.data.text, isNot(contains('Magari sono sul terrazzo')));

      await tester.drag(find.byType(CampanelloCard), const Offset(-500, 0));
      await tester.pumpAndSettle();
      card = tester.widget(find.byType(CampanelloCard));
      expect(card.data.text, contains('una casa'));

      await tester.tap(find.text('Clicca qui'));
      await tester.pumpAndSettle();

      expect(find.byType(EmailLoginPage), findsOneWidget);
    },
  );

  testWidgets(
    'un utente autenticato entra sul proprio campanello e poi vede gli altri',
    (tester) async {
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
          'campanello_hinoo_id': 'newer',
          'owner_id': 'user-3',
          'created_at': '2026-08-03T10:00:00Z',
        },
        {
          'campanello_hinoo_id': 'owned',
          'owner_id': 'test_user',
          'created_at': '2026-08-04T10:00:00Z',
        },
        {
          'campanello_hinoo_id': 'older',
          'owner_id': 'user-2',
          'created_at': '2026-08-01T10:00:00Z',
        },
      ]);
      settings.queueResponse(const []);
      hinoo.queueResponse(const [
        {
          'id': 'newer',
          'pages': [
            {'text': 'Campanello più recente'},
          ],
        },
        {
          'id': 'owned',
          'pages': [
            {'text': 'Il mio campanello'},
          ],
        },
        {
          'id': 'older',
          'pages': [
            {'text': 'Campanello più vecchio'},
          ],
        },
      ]);
      houseAccess
        ..queueResponse(const [])
        ..queueResponse(const []);
      houseInvites.queueResponse(const []);

      await tester.pumpWidget(const MaterialApp(home: CampanelliPage()));
      await tester.pumpAndSettle();

      CampanelloCard card = tester.widget(find.byType(CampanelloCard));
      expect(card.data.text, 'Il mio campanello');

      await tester.drag(find.byType(CampanelloCard), const Offset(-500, 0));
      await tester.pumpAndSettle();
      card = tester.widget(find.byType(CampanelloCard));
      expect(card.data.text, 'Campanello più vecchio');
    },
  );
}
